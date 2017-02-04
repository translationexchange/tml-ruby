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

require 'rubygems'
require 'rubygems/package'
require 'open-uri'
require 'zlib'
require 'fileutils'

module Tml

  def self.cache
    @cache ||= begin
      if Tml.config.cache_enabled?
        # .capitalize is not ideal, but .camelcase is not available in pure ruby.
        # This works for the current class names.
        klass = Tml::CacheAdapters.const_get(Tml.config.cache[:adapter].to_s.capitalize)
        klass.new
      else
        # blank implementation
        Tml::Cache.new
      end
    end
  end

  class Cache

    # version object
    def version
      @version ||= Tml::CacheVersion.new(self)
    end

    # resets current version
    def reset_version
      version.reset
    end

    # upgrade current version
    def upgrade_version
      version.upgrade
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

    def namespace=(value)
      @namespace = value
    end

    # namespace of each cache key
    def namespace
      return '#' if Tml.config.disabled?
      @namespace || Tml.config.cache[:namespace] || Tml.config.application[:key][0..5]
    end

    # versioned name of cache key
    def versioned_key(key, opts = {})
      version.versioned_key(key, namespace)
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

    # Pulls cache version from CDN
    def extract_version(app, version = nil)
      if version
        Tml.cache.version.set(version.to_s)
      else
        version_data = app.api_client.get_from_cdn('version', {t: Time.now.to_i}, {uncompressed: true})

        unless version_data
          Tml.logger.debug('No releases have been generated yet. Please visit your Dashboard and publish translations.')
          return
        end

        Tml.cache.version.set(version_data['version'])
      end
    end

    # Warms up cache from CDN or local files
    def warmup(version = nil, cache_path = nil)
      if cache_path.nil?
        warmup_from_cdn(version)
      else
        warmup_from_files(version, cache_path)
      end
    end

    # Warms up cache from local files
    def warmup_from_files(version = nil, cache_path = nil)
      t0 = Time.now
      Tml.logger = Logger.new(STDOUT)

      Tml.logger.debug('Starting cache warmup from local files...')
      version ||= Tml.config.cache[:version]
      cache_path ||= Tml.config.cache[:path]
      cache_path = "#{cache_path}/#{version}"

      Tml.cache.version.set(version.to_s)
      Tml.logger.debug("Warming Up Version: #{Tml.cache.version}")

      application = JSON.parse(File.read("#{cache_path}/application.json"))
      Tml.cache.store(Tml::Application.cache_key, application)

      sources = JSON.parse(File.read("#{cache_path}/sources.json"))

      application['languages'].each do |lang|
        locale = lang['locale']

        language = JSON.parse(File.read("#{cache_path}/#{locale}/language.json"))
        Tml.cache.store(Tml::Language.cache_key(locale), language)

        sources.each do |src|
          source = JSON.parse(File.read("#{cache_path}/#{locale}/sources/#{src}.json"))
          Tml.cache.store(Tml::Source.cache_key(locale, src), source)
        end
      end

      t1 = Time.now
      Tml.logger.debug("Cache warmup took #{t1-t0}s")
    end

    # Warms up cache from CDN
    def warmup_from_cdn(version = nil)
      t0 = Time.now
      Tml.logger = Logger.new(STDOUT)

      Tml.logger.debug('Starting cache warmup from CDN...')
      app = Tml::Application.new(key: Tml.config.application[:key], cdn_host: Tml.config.application[:cdn_host])
      extract_version(app, version)

      Tml.logger.debug("Warming Up Version: #{Tml.cache.version}")

      application = app.api_client.get_from_cdn('application', {t: Time.now.to_i})
      Tml.cache.store(Tml::Application.cache_key, application)

      sources = app.api_client.get_from_cdn('sources', {t: Time.now.to_i}, {uncompressed: true})

      application['languages'].each do |lang|
        locale = lang['locale']
        language = app.api_client.get_from_cdn("#{locale}/language", {t: Time.now.to_i})
        Tml.cache.store(Tml::Language.cache_key(locale), language)

        sources.each do |src|
          source = app.api_client.get_from_cdn("#{locale}/sources/#{src}", {t: Time.now.to_i})
          Tml.cache.store(Tml::Source.cache_key(locale, src), source)
        end
      end

      t1 = Time.now
      Tml.logger.debug("Cache warmup took #{t1-t0}s")
    end

    # default cache path
    def default_cache_path
      @cache_path ||= begin
        path = Tml.config.cache[:path]
        path ||= 'config/tml'
        FileUtils.mkdir_p(path)
        FileUtils.chmod(0777, path)
        path
      end
    end

    # downloads cache from the CDN
    def download(cache_path = default_cache_path, version = nil)
      t0 = Time.now
      Tml.logger = Logger.new(STDOUT)

      Tml.logger.debug('Starting cache download...')
      app = Tml::Application.new(key: Tml.config.application[:key], cdn_host: Tml.config.application[:cdn_host])
      extract_version(app, version)

      Tml.logger.debug("Downloading Version: #{Tml.cache.version}")

      archive_name = "#{Tml.cache.version}.tar.gz"
      path = "#{cache_path}/#{archive_name}"
      url = "#{app.cdn_host}/#{Tml.config.application[:key]}/#{archive_name}"

      Tml.logger.debug("Downloading cache file: #{url}")
      open(path, 'wb') do |file|
        file << open(url).read
      end

      Tml.logger.debug('Extracting cache file...')
      version_path = "#{cache_path}/#{Tml.cache.version}"
      Tml::Utils.untar(Tml::Utils.ungzip(File.new(path)), version_path)
      Tml.logger.debug("Cache has been stored in #{version_path}")

      File.unlink(path)

      begin
        current_path = 'current'
        FileUtils.chdir(cache_path)
        FileUtils.rm(current_path) if File.exist?(current_path)
        FileUtils.ln_s(Tml.cache.version.to_s, current_path)
        Tml.logger.debug("The new version #{Tml.cache.version} has been marked as current")
      rescue Exception => ex
        Tml.logger.debug("Could not generate current symlink to the cache path: #{ex.message}")
      end

      t1 = Time.now
      Tml.logger.debug("Cache download took #{t1-t0}s")
    end

    # remove extensions
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
