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

class Tml::Api::Client < Tml::Base
  API_HOST = 'https://api.translationexchange.com'
  API_PATH = '/v1'

  attributes :application

  def access_token
    return Tml::Session.access_token if Tml::Session.access_token

    application.access_token ||= begin
      token = Tml.cache.fetch("#{application.key}/access_token") do
        api('oauth/token', {
          :client_id      => application.key,
          :client_secret  => application.secret,
          :grant_type     => :client_credentials
        }, {:method => :post})
      end
      Tml::Session.access_token = token['access_token']
      Tml::Session.access_token
    end
  end

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

  def connection
    @connection ||= Faraday.new(:url => host) do |faraday|
      faraday.request(:url_encoded)               # form-encode POST params
      # faraday.response :logger                  # log requests to STDOUT
      faraday.adapter(Faraday.default_adapter)    # make requests with Net::HTTP
    end
  end

  def api(path, params = {}, opts = {})
    if Tml.session.inline_mode?
      return process_response(execute_request(path, params, opts), opts)
    end

    if opts[:method] == :get and opts[:cache_key]
      data = Tml.cache.fetch(opts[:cache_key]) do
        Tml.cache.read_only? ? nil : execute_request(path, params, opts)
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

  def execute_request(path, params = {}, opts = {})
    response = nil
    error = nil

    # oauth path is separate from versioned APIs
    path = prepare_api_path(path)
    params = params.merge(:access_token => access_token) unless path.index('oauth')

    if opts[:method] == :post
      params = params.merge(:api_key => application.key)
    end

    Tml.logger.trace_api_call(path, params, opts) do
      begin
        if opts[:method] == :post
          response = connection.post(path, params)
        elsif opts[:method] == :put
          response = connection.put(path, params)
        elsif opts[:method] == :delete
          response = connection.delete(path, params)
        else
          response = connection.get(path, params)
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

    return if response.body.nil? or response.body == ''

    begin
      data = JSON.parse(response.body)
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

end
