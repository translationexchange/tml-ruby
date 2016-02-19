# encoding: UTF-8
#--
# Copyright (c) 2016 Translation Exchange, Inc
#
#  _______                  _       _   _             ______          _
# |__   __|                | |     | | (_)           |  ____|        | |
#    | |_ __ __ _ _ __  ___| | __ _| |_ _  ___  _ __ | |__  __  _____| |__   __ _ _ __   __ _  ___
#    | | '__/ _` | '_ \/ __| |/ _` | __| |/ _ \| '_ \|  __| \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
#    | | | | (_| | | | \__ \ | (_| | |_| | (_) | | | | |____ >  < (__| | | | (_| | | | | (_| |  __/
#    |_|_|  \__,_|_| |_|___/_|\__,_|\__|_|\___/|_| |_|______/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
#                                                                                        __/ |
#                                                                                       |___/
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'faraday'
require 'zlib'
require 'stringio'

class Tml::Api::Client < Tml::Base
  API_PATH = '/v1'

  attributes :application

  # get results from API
  def results(path, params = {}, opts = {})
    get(path, params, opts)['results']
  end

  # get from API
  def get(path, params = {}, opts = {})
    api(path, params, opts.merge(:method => :get))
  end

  # post to API
  def post(path, params = {}, opts = {})
    api(path, params, opts.merge(:method => :post))
  end

  # put to API
  def put(path, params = {}, opts = {})
    api(path, params, opts.merge(:method => :put))
  end

  # delete from API
  def delete(path, params = {}, opts = {})
    api(path, params, opts.merge(:method => :delete))
  end

  # checks if there are any API errors
  def self.error?(data)
    not data['error'].nil?
  end

  # API connection
  def connection
    @connection ||= Faraday.new(:url => application.host) do |faraday|
      faraday.request(:url_encoded)               # form-encode POST params
      # faraday.response :logger                  # log requests to STDOUT
      faraday.adapter(Faraday.default_adapter)    # make requests with Net::HTTP
    end
  end

  # get cache version from CDN
  def get_cache_version
    t = Tml::Utils.interval_timestamp(Tml.config.version_check_interval)
    Tml.logger.debug("Fetching cache version from CDN with timestamp: #{t}")

    data = get_from_cdn('version', {t: t}, {public: true, uncompressed: true})

    unless data
      Tml.logger.debug('No releases have been published yet')
      return '0'
    end

    data['version']
  end

  # verify cache version
  def verify_cache_version
    return if Tml.cache.version.defined?

    current_version = Tml.cache.version.fetch

    if current_version == 'undefined'
      Tml.cache.version.store(get_cache_version)
    else
      Tml.cache.version.set(current_version)
    end

    Tml.logger.info("Version: #{Tml.cache.version}")
  end

  def cdn_connection
    @cdn_connection ||= Faraday.new(:url => application.cdn_host) do |faraday|
      faraday.request(:url_encoded)               # form-encode POST params
      faraday.adapter(Faraday.default_adapter)    # make requests with Net::HTTP
    end
  end

  def get_from_cdn(key, params = {}, opts = {})
    if Tml.cache.version.invalid? and key != 'version'
      return nil
    end

    response = nil
    cdn_path = "/#{application.key}"

    if key == 'version'
      cdn_path += "/#{key}.json"
    else
      cdn_path += "/#{Tml.cache.version.to_s}/#{key}.json.gz"
    end

    trace_api_call(cdn_path, params, opts.merge(:host => application.cdn_host)) do
      begin
        response = cdn_connection.get do |request|
          prepare_request(request, cdn_path, params)
        end
      rescue Exception => ex
        Tml.logger.error("Failed to execute request: #{ex.message[0..255]}")
        return nil
      end
    end
    return if response.status >= 500 and response.status < 600
    return if response.body.nil? or response.body == '' or response.body.match(/xml/)

    compressed_data = response.body
    return if compressed_data.nil? or compressed_data == ''

    data = compressed_data

    unless opts[:uncompressed]
      data = Zlib::GzipReader.new(StringIO.new(compressed_data.to_s)).read
      Tml.logger.debug("Compressed: #{compressed_data.length} Uncompressed: #{data.length}")
    end

    begin
      data = JSON.parse(data)
    rescue Exception => ex
      return nil
    end

    data
  end

  def access_token
    application.token
  end

  def live_api_request?
    # if no access token, never use live mode
    return false if access_token.blank?

    # if block is specifically asking for it or inline mode is activated
    Tml.session.inline_mode? or Tml.session.block_option(:live)
  end

  def enable_cache?(opts)
    # only gets ever get cached
    return false unless opts[:method] == :get
    return false if opts[:cache_key].nil?
    return false unless Tml.cache.enabled?
    true
  end

  def api(path, params = {}, opts = {})
    # inline mode should always bypass API calls
    if live_api_request?
      process_response(execute_request(path, params, opts), opts)
    else
      # get request uses local cache, then CDN
      data = nil
      if enable_cache?(opts)
        verify_cache_version
        unless Tml.cache.version.invalid?
          data = Tml.cache.fetch(opts[:cache_key]) do
            if Tml.cache.read_only?
              # read only cache is either there, or no data
              nil
            else
              # get date from the CDN
              get_from_cdn(opts[:cache_key])
            end
          end
        end
      end
      process_response(data, opts)
    end
  end

  def paginate(path, params = {}, opts = {})
    data = get(path, params, opts.merge({'raw' => true}))

    while data
      if data['results'].is_a?(Array)
        data['results'].each do |result|
          yield(result)
        end
      else
        yield(data['results'])
      end

      if data['pagination'] and data['pagination']['links']['next']
        data = get(data['pagination']['links']['next'], {}, opts.merge({'raw' => true}))
      else
        data = nil
      end
    end
  end

  def prepare_api_path(path)
    return path if path.match(/^https?:\/\//)
    "#{API_PATH}#{path[0] == '/' ? '' : '/'}#{path}"
  end

  def prepare_request(request, path, params)
    request.options.timeout = 5
    request.options.open_timeout = 2
    request.headers['User-Agent']       = "tml-ruby v#{Tml::VERSION} (Faraday v#{Faraday::VERSION})"
    request.headers['Accept']           = 'application/json'
    request.headers['Accept-Encoding']  = 'gzip, deflate'
    request.url(path, params)
  end

  def execute_request(path, params = {}, opts = {})
    response = nil
    error = nil

    path = prepare_api_path(path)

    unless opts[:public]
      params = params.merge(:access_token => access_token)
    end

    if opts[:method] == :post
      params = params.merge(:app_id => application.key)
    end

    @compressed = false
    trace_api_call(path, params, opts.merge(:host => application.host)) do
      begin
        if opts[:method] == :post
          response = connection.post(path, params)
        elsif opts[:method] == :put
          response = connection.put(path, params)
        elsif opts[:method] == :delete
          response = connection.delete(path, params)
        else
          response = connection.get do |request|
            @compressed = true
            prepare_request(request, path, params)
          end
        end
      rescue Exception => ex
        Tml.logger.error("Failed to execute request: #{ex.message[0..255]}")
        error = ex
        nil
      end
    end
    raise Tml::Exception.new("Error: #{error}") if error

    if response.status >= 500 and response.status < 600
      raise Tml::Exception.new("Error: #{response.body}")
    end

    if @compressed and (not opts[:uncompressed])
      compressed_data = response.body
      return if compressed_data.nil? or compressed_data == ''

      data = Zlib::GzipReader.new(StringIO.new(compressed_data.to_s)).read
      Tml.logger.debug("Compressed: #{compressed_data.length} Uncompressed: #{data.length}")
    else
      data = response.body
    end

    return data if opts[:raw]

    begin
      data = JSON.parse(data)
    rescue Exception => ex
      raise Tml::Exception.new("Failed to parse response: #{ex.message[0..255]}")
    end

    if data.is_a?(Hash) and not data['error'].nil?
      raise Tml::Exception.new("Error: #{data['error']}")
    end

    data
  end

  def object_class(opts)
    return unless opts[:class]
    opts[:class].is_a?(String) ? opts[:class].constantize : opts[:class]
  end

  def process_response(data, opts)
    return nil if data.nil?
    return data if opts[:raw] or opts[:raw_json]

    if data.is_a?(Hash) and data['results']
      #Tml.logger.debug("received #{data['results'].size} result(s)")
      return data['results'] unless object_class(opts)
      objects = []
      data['results'].each do |data|
        objects << object_class(opts).new(data.merge(opts[:attributes] || {}))
      end
      return objects
    end

    return data unless object_class(opts)
    object_class(opts).new(data.merge(opts[:attributes] || {}))
  end

  def to_query(hash)
    query = []
    hash.each do |key, value|
      query << "#{key.to_s}=#{value.to_s}"
    end
    query.join('&')
  end

  def trace_api_call(path, params, opts = {})
    #[:client_secret, :access_token].each do |param|
    #  params = params.merge(param => "##filtered##") if params[param]
    #end

    path = "#{path[0] == '/' ? '' : '/'}#{path}"

    if opts[:method] == :post
      Tml.logger.debug("post: #{opts[:host]}#{path}")
    else
      if params.any?
        Tml.logger.debug("get: #{opts[:host]}#{path}?#{to_query(params)}")
      else
        Tml.logger.debug("get: #{opts[:host]}#{path}")
      end
    end

    t0 = Time.now
    if block_given?
      ret = yield
    end
    t1 = Time.now

    Tml.logger.debug("call took #{t1 - t0} seconds")
    ret
  end

end
