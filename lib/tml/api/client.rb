# encoding: UTF-8
#--
# Copyright (c) 2017 Translation Exchange, Inc
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

  # API Host
  def host
    application.host
  end

  # API connection
  def connection
    @connection ||= Faraday.new(:url => host) do |faraday|
      faraday.request(:url_encoded) # form-encode POST params
      # faraday.response :logger                  # log requests to STDOUT
      faraday.adapter(Faraday.default_adapter) # make requests with Net::HTTP
    end
  end

  # get cache version from CDN
  def get_cache_version
    data = get_from_cdn('version', {t: Time.now.to_i}, {public: true, uncompressed: true})

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

    Tml.logger.info("Cache Version: #{Tml.cache.version}")
  end

  def cdn_host
    @cdn_host ||= URI.join(application.cdn_host, '/').to_s
  end

  def get_cdn_path(key, opts = {})
    base_path = URI(application.cdn_host).path
    base_path += '/' unless base_path.last == '/'

    adjusted_path = "#{base_path}#{application.key}/"

    if key == 'version'
      adjusted_path += "#{key}.json"
    else
      adjusted_path += "#{Tml.cache.version.to_s}/#{key}.json#{opts[:uncompressed] ? '' : '.gz'}"
    end

    pp adjusted_path
    adjusted_path
  end

  # cdn_connection
  def cdn_connection
    @cdn_connection ||= Faraday.new(:url => cdn_host) do |faraday|
      faraday.request(:url_encoded) # form-encode POST params
      faraday.adapter(Faraday.default_adapter) # make requests with Net::HTTP
    end
  end

  # get from the CDN
  def get_from_cdn(key, params = {}, opts = {})
    if Tml.cache.version.invalid? and key != 'version'
      return nil
    end

    response = nil
    cdn_path = get_cdn_path(key, opts)

    trace_api_call(cdn_path, params, opts.merge(:host => application.cdn_host)) do
      begin
        response = cdn_connection.get do |request|
          prepare_request(request, cdn_path, params, opts)
        end
      rescue => ex
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
    rescue => ex
      return nil
    end

    data
  end

  # access token
  def access_token
    application.token
  end

  # should the API go to live server
  def live_api_request?
    # if no access token, never use live mode
    return false if access_token.nil?

    # if block is specifically asking for it or inline mode is activated
    Tml.session.inline_mode? or Tml.session.block_option(:live)
  end

  # checks if cache is enable
  def cache_enabled?(opts)
    # only gets ever get cached
    return false unless opts[:method] == :get
    return false if opts[:cache_key].nil?
    return false unless Tml.cache.enabled?
    true
  end

  # checks mode and cache, and fetches data
  def api(path, params = {}, opts = {})
    # inline mode should always use API calls
    if live_api_request?
      params = params.merge(:access_token => access_token, :app_id => application.key)
      return process_response(execute_request(path, params, opts), opts)
    end

    return unless cache_enabled?(opts)

    # ensure the cache version is not outdated
    verify_cache_version

    return if Tml.cache.version.invalid?

    # get request uses local cache, then CDN
    data = Tml.cache.fetch(opts[:cache_key]) do
      fetched_data = get_from_cdn(opts[:cache_key]) unless Tml.cache.read_only?
      fetched_data || {}
    end

    process_response(data, opts)
  end

  # paginates through API results
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

  # prepares API path
  def prepare_api_path(path)
    return path if path.match(/^https?:\/\//)
    clean_path = trim_prepending_slash(path)

    if clean_path.index('v1') == 0 || clean_path.index('v2') == 0
      "/#{clean_path}"
    else
      "#{API_PATH}/#{clean_path}"
    end
  end

  def trim_prepending_slash(str)
    str.index('/') == 0 ? str[1..-1] : str
  end

  # prepares request
  def prepare_request(request, path, params, opts = {})
    request.options.timeout = Tml.config.api_client[:timeout]
    request.options.open_timeout = Tml.config.api_client[:open_timeout]
    request.headers['User-Agent'] = "tml-ruby v#{Tml::VERSION} (Faraday v#{Faraday::VERSION})"
    request.headers['Accept'] = 'application/json'

    unless opts[:uncompressed]
      request.headers['Accept-Encoding'] = 'gzip, deflate'
    end

    request.url(path, params)
  end

  # execute API request
  def execute_request(path, params = {}, opts = {})
    response = nil
    error = nil

    path = prepare_api_path(path)

    opts[:method] ||= :get

    trace_api_call(path, params, opts.merge(:host => host)) do
      begin
        if opts[:method] == :post
          response = connection.post(path, params)
        elsif opts[:method] == :put
          response = connection.put(path, params)
        elsif opts[:method] == :delete
          response = connection.delete(path, params)
        else
          response = connection.get do |request|
            prepare_request(request, path, params, opts)
          end
        end
      rescue => ex
        Tml.logger.error("Failed to execute request: #{ex.message[0..255]}")
        error = ex
        nil
      end
    end

    if error
      raise Tml::Exception.new("Error: #{error}")
    end

    if response.status >= 500 && response.status < 600
      raise Tml::Exception.new("Error: #{response.body}")
    end

    if opts[:method] == :get && !opts[:uncompressed]
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
    rescue => ex
      raise Tml::Exception.new("Failed to parse response: #{ex.message[0..255]}")
    end

    if data.is_a?(Hash) and not data['error'].nil?
      raise Tml::Exception.new("Error: #{data['error']}")
    end

    data
  end

  # get object class from options
  def object_class(opts)
    return unless opts[:class]
    opts[:class].is_a?(String) ? opts[:class].constantize : opts[:class]
  end

  # process API response
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

  # convert params to query
  def to_query(hash)
    query = []
    hash.each do |key, value|
      query << "#{key.to_s}=#{value.to_s}"
    end
    query.join('&')
  end

  # trace api call for logging
  def trace_api_call(path, params, opts = {})
    if Tml.config.logger[:secure]
      [:access_token].each do |param|
        params = params.merge(param => "##filtered##") if params[param]
      end
    end

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
