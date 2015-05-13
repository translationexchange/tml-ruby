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

  CACHE_VERSION_KEY = '__tml_version__'

  def self.memory
    @memory ||= Tml::CacheAdapters::Memory.new
  end

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

    def version
      Tml.config.cache[:version] ||= 1

      @version ||= begin
        v = fetch(CACHE_VERSION_KEY) do
          {'version' => Tml.config.cache[:version]}
        end
        v.is_a?(Hash) ? v['version'] : v
      end

      @version ||= Tml.config.cache[:version]

      if Tml.config.cache[:version] > @version
        update_version(Tml.config.cache[:version])
        @version = Tml.config.cache[:version]
      end

      @version
    end

    def update_version(new_version)
      store(CACHE_VERSION_KEY, {'version' => new_version}, :ttl => 0)
    end

    def upgrade_version
      update_version((version || Tml.config.cache[:version] || 0).to_i + 1)
      @version = nil
    end

    def reset_version
      @version = nil
    end

    def enabled?
      Tml.config.cache[:enabled]
    end

    def cached_by_source?
      true
    end

    def read_only?
      false
    end

    def segmented?
      true
    end

    def cache_name
      self.class.name.split('::').last
    end

    def info(msg)
      Tml.logger.info("#{cache_name} - #{msg}")
    end

    def warn(msg)
      Tml.logger.warn("#{cache_name} - #{msg}")
    end

    def versioned_key(key, opts = {})
      return key if CACHE_VERSION_KEY == key
      "tml_rc_v#{version}_#{key}"
    end

    def fetch(key, opts = {})
      return nil unless block_given?
      yield
    end

    def store(key, data, opts = {})
      # do nothing
    end

    def delete(key, opts = {})
      # do nothing
    end

    def exist?(key, opts = {})
      false
    end

    def clear(opts = {})
      # do nothing
    end

  end
end
