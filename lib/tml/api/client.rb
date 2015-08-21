# encoding: UTF-8
#--
# Copyright (c) 2015 Translation Exchange, Inc
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
  CDN_HOST = 'https://cdn.translationexchange.com'
  API_HOST = 'https://api.translationexchange.com'
  API_PATH = '/v1'

  attributes :application

  # get results from api
  def results(path, params = {}, opts = {})
    get(path, params, opts)['results']
  end

  def get(path, params = {}, opts = {})
    api(path, params, opts.merge(:method => :get))
  end

  def post(path, params = {}, opts = {})
    api(path, params, opts.merge(:method => :post))
  end

  def put(path, params = {}, opts = {})
    api(path, params, opts.merge(:method => :put))
  end

  def delete(path, params = {}, opts = {})
    api(path, params, opts.merge(:method => :delete))
  end

  def self.error?(data)
    not data['error'].nil?
  end

  def host
    application.host || API_HOST
  end

  def cdn_host
    CDN_HOST
  end

  def connection
    @connection ||= Faraday.new(:url => host) do |faraday|
      faraday.request(:url_encoded)               # form-encode POST params
      # faraday.response :logger                  # log requests to STDOUT
      faraday.adapter(Faraday.default_adapter)    # make requests with Net::HTTP
    end
  end

  def get_cache_version
    execute_request('applications/current/version', {}, {:raw => true})
  end

  def verify_cache_version
    return if Tml.cache.version and Tml.cache.version != 'undefined'

    current_version = Tml.cache.fetch_version
    if current_version == 'undefined'
      Tml.cache.store_version(get_cache_version)
    else
      Tml.cache.version = current_version
    end
    Tml.logger.info("Version: #{Tml.cache.version}")
  end

  def cdn_connection
    @cdn_connection ||= Faraday.new(:url => cdn_host) do |faraday|
      faraday.request(:url_encoded)               # form-encode POST params
      faraday.adapter(Faraday.default_adapter)    # make requests with Net::HTTP
    end
  end

  def get_from_cdn(key, params = {}, opts = {})
    return nil if Tml.cache.version == 'undefined' || Tml.cache.version.to_s == '0'

    response = nil
    cdn_path = "/#{Tml.config.application[:key]}/#{Tml.cache.version}/#{key}.json.gz"
    trace_api_call(cdn_path, params, opts.merge(:host => cdn_host)) do
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

    data = Zlib::GzipReader.new(StringIO.new(compressed_data.to_s)).read
    Tml.logger.debug("Compressed: #{compressed_data.length} Uncompressed: #{data.length}")

    begin
      data = JSON.parse(data)
    rescue Exception => ex
      return nil
    end

    data
  end

  def api(path, params = {}, opts = {})
    # inline mode should always bypass API calls
    # get request uses local cache, then CDN, the API
    if opts[:method] == :get and opts[:cache_key] and Tml.cache.enabled? and not Tml.session.inline_mode?
      verify_cache_version
      data = Tml.cache.fetch(opts[:cache_key]) do
        if Tml.cache.read_only?
          nil
        else
          get_from_cdn(opts[:cache_key]) || execute_request(path, params, opts)
        end
      end
      process_response(data, opts)
    else
      process_response(execute_request(path, params, opts), opts)
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
    return path if path.index('oauth')
    return path if path.match(/^https?:\/\//)
    "#{API_PATH}#{path[0] == '/' ? '' : '/'}#{path}"
  end

  def prepare_request(request, path, params)
    request.options.timeout = 5
    request.options.open_timeout = 2
    request.headers['User-Agent']       = "tml-ruby v#{Tml::VERSION} (Faraday v#{Faraday::VERSION}"
    request.headers['Accept']           = 'application/json'
    request.headers['Accept-Encoding']  = 'gzip, deflate'
    request.url(path, params)
  end

  def execute_request(path, params = {}, opts = {})
    response = nil
    error = nil

    token = Tml.config.application ? Tml.config.application[:token] : ''

    # oauth path is separate from versioned APIs
    path = prepare_api_path(path)
    params = params.merge(:access_token => token) unless path.index('oauth')

    if opts[:method] == :post
      params = params.merge(:api_key => application.key)
    end

    @compressed = false
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

    if @compressed
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
    return data if opts['raw']

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
      query << "#{key}=#{value}"
    end
    query.join('&')
  end

  def trace_api_call(path, params, opts = {})
    #[:client_secret, :access_token].each do |param|
    #  params = params.merge(param => "##filtered##") if params[param]
    #end

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
