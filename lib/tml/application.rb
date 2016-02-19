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

class Tml::Application < Tml::Base

  # CDN_HOST = 'https://cdn.translationexchange.com'
  CDN_HOST = 'https://trex-snapshots.s3-us-west-1.amazonaws.com'
  API_HOST = 'https://api.translationexchange.com'

  attributes :host, :id, :key, :access_token,  :name, :description, :threshold, :default_locale, :default_level, :tools
  has_many :features, :languages, :languages_by_locale, :sources, :tokens, :css, :shortcuts, :translations, :extensions
  has_many :ignored_keys

  # Returns application cache key
  def self.cache_key
    'application'
  end

  # Returns translations cache key
  def self.translations_cache_key(locale)
    "#{locale}/translations"
  end

  def token
    access_token
  end

  def host
    super || API_HOST
  end

  def cdn_host
    CDN_HOST
  end

  # Fetches application definition from the service
  def fetch
    data = api_client.get("projects/#{key}/definition",{
      locale: Tml.session.current_locale,
      source: Tml.session.current_source,
      ignored: true
    }, {
      cache_key: self.class.cache_key
    })

    if data
      update_attributes(data)
    else
      add_language(Tml.config.default_language)
      Tml.logger.debug('Cache enabled but no data is provided.')
    end

    self
  rescue Tml::Exception => ex
    Tml.logger.error("Failed to load application: #{ex}")
    self
  end

  # Updates application attributes
  def update_attributes(attrs)
    super

    self.attributes[:languages] = []
    if hash_value(attrs, :languages)
      self.attributes[:languages] = hash_value(attrs, :languages).collect{ |l| Tml::Language.new(l.merge(:application => self)) }
    end

    load_extensions(hash_value(attrs, :extensions))

    self
  end

  # Loads application extensions, if any
  def load_extensions(extensions)
    return if extensions.nil?
    source_locale = default_locale

    cache = Tml.cache
    cache = nil if not Tml.cache.enabled? or Tml.session.inline_mode?

    if hash_value(extensions, :languages)
      self.languages_by_locale ||= {}
      hash_value(extensions, :languages).each do |locale, data|
        source_locale = locale if locale != source_locale
        cache.store(Tml::Language.cache_key(locale), data) if cache
        self.languages_by_locale[locale] = Tml::Language.new(data.merge(
          locale: locale,
          application: self
        ))
      end
    end

    if hash_value(extensions, :sources)
      self.sources ||= {}
      hash_value(extensions, :sources).each do |source, data|
        cache.store(Tml::Source.cache_key(source_locale, source), data) if cache
        self.sources[source] ||= Tml::Source.new(
          application:  self,
          source:       source
        )
        self.sources[source].update_translations(source_locale, data)
      end
    end
  end

  # Returns language by locale
  def language(locale = nil)
    locale = nil if locale and locale.strip == ''

    locale ||= default_locale || Tml.config.default_locale
    locale = locale.to_s

    self.languages_by_locale ||= {}
    self.languages_by_locale[locale] ||= api_client.get("languages/#{locale}/definition", {
    }, {
      class:      Tml::Language,
      attributes: {locale: locale, application: self},
      cache_key:  Tml::Language.cache_key(locale)
    })
  rescue Tml::Exception => e
    Tml.logger.error(e)
    Tml.logger.error(e.backtrace)
    self.languages_by_locale[locale] = Tml.config.default_language
  end

  # Normalizes and returns current language
  def current_language(locale)
    return Tml.config.default_language unless locale
    locale = locale.gsub('_', '-') if locale
    lang = language(locale)
    lang ||= language(locale.split('-').first) if locale.index('-')
    lang ||= Tml.config.default_language
    lang
  end

  # Adds a language to the application
  def add_language(new_language)
    self.languages_by_locale ||= {}
    return self.languages_by_locale[new_language.locale] if self.languages_by_locale[new_language.locale]
    new_language.application = self
    self.languages << new_language
    self.languages_by_locale[new_language.locale] = new_language
    new_language
  end

  # Returns a list of application supported locales
  def locales
    @locales ||= languages.collect{|lang| lang.locale}
  end

  # Returns tools data
  def tools
    @attributes[:tools] || {}
  end

  # Returns asset url
  def url_for(path)
    "#{tools['assets']}#{path}"
  end

  # Returns source by key
  def source(key, locale)
    self.sources ||= {}
    self.sources[key] ||= Tml::Source.new(
      :application  => self,
      :source       => key
    ).fetch_translations(locale)
  end

  # Verifies current source path
  def verify_source_path(source_key, source_path)
    return if Tml.cache.enabled? and not Tml.session.inline_mode?
    return if extensions.nil? or extensions['sources'].nil?
    return unless extensions['sources'][source_key].nil?
    @missing_keys_by_sources ||= {}
    @missing_keys_by_sources[source_path] ||= {}
  end

  def register_missing_key(source_key, tkey)
    return if Tml.cache.enabled? and not Tml.session.inline_mode?
    source_key = source_key.to_s
    @missing_keys_by_sources ||= {}
    @missing_keys_by_sources[source_key] ||= {}
    @missing_keys_by_sources[source_key][tkey.key] ||= tkey
    submit_missing_keys if Tml.config.submit_missing_keys_realtime
  end

  def register_keys(keys)
    params = []
    keys.each do |source_key, keys|
      source = Tml::Source.new(:source => source_key, :application => self)
      params << {:source => source_key, :keys => keys.values.collect{|tkey| tkey.to_hash(:label, :description, :locale, :level)}}
      source.reset_cache
    end

    api_client.post('sources/register_keys', {:source_keys => params.to_json})
  rescue Tml::Exception => e
    Tml.logger.error('Failed to register missing translation keys...')
    Tml.logger.error(e)
    Tml.logger.error(e.backtrace)
  end

  def submit_missing_keys
    return if @missing_keys_by_sources.nil? or @missing_keys_by_sources.empty?
    register_keys(@missing_keys_by_sources)
    @missing_keys_by_sources = nil
  end

  def reset_translation_cache
    self.sources = {}
    self.translations = {}
    @languages_by_locale      = nil
    @missing_keys_by_sources  = nil
  end

  def ignored_key?(key)
    return false if ignored_keys.nil?
    not ignored_keys.index(key).nil?
  end

  def fetch_translations(locale)
    self.translations ||= {}
    self.translations[locale] ||= begin
      results = Tml.cache.fetch(Tml::Application.translations_cache_key(locale)) do
        data = {}
        unless Tml.cache.read_only?
          data = api_client.get("projects/#{key}/translations", :all => true, :ignored => true, :raw_json => true)
        end
        data
      end

      if results.is_a?(Hash) and results['results']
        results = results['results']
        self.ignored_keys = results['ignored_keys'] || []
      end

      translations_by_key = {}
      results.each do |key, data|
        translations_data = data.is_a?(Hash) ? data['translations'] : data
        translations_by_key[key] = translations_data.collect do |t|
          Tml::Translation.new(
            :locale => t['locale'] || locale,
            :label => t['label'],
            :locked => t['locked'],
            :context => t['context']
          )
        end
      end
      translations_by_key
    end
  rescue Tml::Exception => ex
    {}
  end

  def cache_translations(locale, key, new_translations)
    self.translations ||= {}
    self.translations[locale] ||= {}
    self.translations[locale][key] = new_translations.collect do |t|
      Tml::Translation.new(
        :locale => t['locale'] || locale,
        :label => t['label'],
        :context => t['context']
      )
    end
  end

  def cached_translations(locale, key)
    return unless self.translations and self.translations[locale]
    self.translations[locale][key]
  end

  def debug_translations
    return 'no translations' unless self.translations
    self.translations.each do |locale, keys|
      pp [locale, keys.collect{|key, translations|
        [key, translations.collect{|t|
          [t.label, t.context]
        }]
      }]
    end
  end

  def default_decoration_token(token)
    hash_value(tokens, "decoration.#{token.to_s}")
  end

  def default_data_token(token)
    hash_value(tokens, "data.#{token.to_s}")
  end

  def feature_enabled?(key)
    hash_value(features, key.to_s)
  end

  def api_client
    @api_client ||= Tml.config.api_client_class.new(application: self)
  end

end
