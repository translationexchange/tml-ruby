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

module Tml

  CACHE_VERSION_KEY = 'current_version'

  class CacheVersion

    attr_accessor :version, :cache

    # Init cache version with cache adapter
    def initialize(cache)
      self.cache = cache
    end

    # reset cache version
    def reset
      self.version = nil
    end

    # updates the current cache version
    def set(new_version)
      self.version = new_version
    end

    # upgrade current version
    def upgrade
      cache.store(CACHE_VERSION_KEY, {'version' => 'undefined', 't' => cache_timestamp})
      reset
    end

    # validate that current cache version hasn't expired
    def validate_cache_version(version)
      # if cache version is hardcoded, use it
      if Tml.config.cache[:version]
        return Tml.config.cache[:version]
      end

      return version unless version.is_a?(Hash)
      return 'undefined' unless version['t'].is_a?(Numeric)
      return version['version'] if cache.read_only?

      # if version check interval is disabled, don't try to check for the new
      # cache version on the CDN
      if version_check_interval == -1
        Tml.logger.debug('Cache version check is disabled')
        return version['version']
      end

      expires_at = version['t'] + version_check_interval
      if expires_at < Time.now.to_i
        Tml.logger.debug('Cache version is outdated, needs refresh')
        return 'undefined'
      end

      delta = expires_at - Time.now.to_i
      Tml.logger.debug("Cache version is up to date, expires in #{delta}s")
      version['version']
    end

    # fetches the version from the cache
    def fetch
      self.version = begin
        ver = cache.fetch(CACHE_VERSION_KEY) do
          {'version' => Tml.config.cache[:version] || 'undefined', 't' => cache_timestamp}
        end
        validate_cache_version(ver)
      end
    end

    # how often should the cache be checked for
    def version_check_interval
      Tml.config.cache[:version_check_interval] || 3600
    end

    # generates cache timestamp based on an interval
    def cache_timestamp
      Tml::Utils.interval_timestamp(version_check_interval)
    end

    # stores the current version back in cache
    def store(new_version)
      self.version = new_version
      cache.store(CACHE_VERSION_KEY, {'version' => new_version, 't' => cache_timestamp})
    end

    # checks if the version is undefined
    def undefined?
      version.nil? or version == 'undefined'
    end

    # checks if version is defined
    def defined?
      not undefined?
    end

    # checks if the version is valid
    def valid?
      not invalid?
    end

    # checks if the version is invalid
    def invalid?
      %w(undefined 0).include?(version.to_s)
    end

    # returns versioned key with prefix
    def versioned_key(key, namespace = '')
      "tml_#{namespace}#{CACHE_VERSION_KEY == key ? '' : "_v#{version}"}_#{key}"
    end

    # returns string representation of the version
    def to_s
      self.version.to_s
    end
  end
end
