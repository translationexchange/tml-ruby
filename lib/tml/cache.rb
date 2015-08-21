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

module Tml

  CACHE_VERSION_KEY = 'current_version'

  def self.cache
    @cache ||= begin
      if Tml.config.cache_enabled?
        klass = Tml::CacheAdapters.const_get(Tml.config.cache[:adapter].to_s.camelcase)
        klass.new
      else
        # blank implementation
        Tml::Cache.new
      end
    end
  end

  class Cache

    # Returns current cache version
    def version
      @version
    end

    # sets the current version
    def version=(new_version)
      @version = new_version
    end

    # resets current version
    def reset_version
      @version = nil
    end

    # upgrade current version
    def upgrade_version
      store(CACHE_VERSION_KEY, {'version' => 'undefined'})
      reset_version
    end

    # fetches the version from the cache
    def fetch_version
      @version ||= begin
        v = fetch(CACHE_VERSION_KEY) do
          {'version' => Tml.config.cache[:version] || 'undefined'}
        end
        v.is_a?(Hash) ? v['version'] : v
      end
    end

    # stores the current version back in cache
    def store_version(new_version)
      @version = new_version
      store(CACHE_VERSION_KEY, {'version' => new_version})
    end

    # checks if Tml is enabled
    def enabled?
      Tml.config.cache_enabled?
    end

    # by default all cache is read/write
    # cache like files based should be set to read only
    def read_only?
      false
    end

    # name of the cache adapter
    def cache_name
      self.class.name.split('::').last
    end

    # logs information messages
    def info(msg)
      Tml.logger.info("#{cache_name} - #{msg}")
    end

    # logs a warning
    def warn(msg)
      Tml.logger.warn("#{cache_name} - #{msg}")
    end

    # namespace of each cache key
    def namespace
      return '#' if Tml.config.disabled?
      Tml.config.cache[:namespace] || Tml.config.access_token[0..5]
    end

    # versioned name of cache key
    def versioned_key(key, opts = {})
      "tml_#{namespace}#{CACHE_VERSION_KEY == key ? '' : "_v#{version}"}_#{key}"
    end

    # fetches key from cache
    def fetch(key, opts = {})
      return nil unless block_given?
      yield
    end

    # stores key in cache
    def store(key, data, opts = {})
      # do nothing
    end

    # deletes key from cache
    def delete(key, opts = {})
      # do nothing
    end

    # checks if the key exists
    def exist?(key, opts = {})
      false
    end

    # clears cache
    def clear(opts = {})
      # do nothing
    end

    def strip_extensions(data)
      if data.is_a?(Hash)
        data = data.dup
        data.delete('extensions')
        return data
      end

      if data.is_a?(String) and data.match(/^\{/)
        data = JSON.parse(data)
        data.delete('extensions')
        data = data.to_json
      end

      data
    end

  end
end
