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


require 'redis' if defined?(::Redis)

class Tml::CacheAdapters::Redis < Tml::Cache

  def initialize
    cache_host, cache_port = Tml.config.cache[:host].split(':') if Tml.config.cache[:host]
    cache_host ||= 'localhost'
    cache_port ||= 6379

    @cache = ::Redis.new(host: cache_host, port: cache_port)
  end

  def cache_name
    'redis'
  end

  def read_only?
    false
  end

  def fetch(key, opts = {})
    data = @cache.get(versioned_key(key, opts))
    if data
      info("Cache hit: #{key}")

      begin
        return JSON.parse(data)
      rescue Exception => ex
        warn("Failed to parse data: #{ex.message}")
      end
    end

    info("Cache miss: #{key}")

    return nil unless block_given?

    data = yield

    store(key, data)

    data
  rescue Exception => ex
    warn("Failed to retrieve data: #{ex.message}")
    pp ex, ex.backtrace
    return nil unless block_given?
    yield
  end

  def store(key, data, opts = {})
    info("Cache store: #{key}")

    ttl = opts[:ttl] || Tml.config.cache[:timeout]
    versioned_key = versioned_key(key, opts)

    @cache.set(versioned_key, data.to_json)
    @cache.expire(versioned_key, ttl) if ttl and ttl > 0
  rescue Exception => ex
    warn("Failed to store data: #{ex.message}")
    data
  end

  def delete(key, opts = {})
    info("Cache delete: #{key}")
    @cache.del(versioned_key(key, opts))
  rescue Exception => ex
    warn("Failed to delete data: #{ex.message}")
    key
  end

  def exist?(key, opts = {})
    data = @cache.exist(versioned_key(key, opts))
    not data.nil?
  rescue Exception => ex
    warn("Failed to check if key exists: #{ex.message}")
    false
  end

  def clear(opts = {})
    info('Cache clear has no effect')
  end

end
