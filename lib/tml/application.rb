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

class Tml::Application < Tml::Base
  attributes :host, :id, :key, :access_token,  :name, :description, :threshold, :default_locale, :default_level, :tools
  has_many :features, :languages, :featured_locales, :sources, :components, :tokens, :css, :shortcuts, :translations

  def self.cache_key
    'application'
  end

  def self.translations_cache_key(locale)
    "#{locale}/translations"
  end

  def fetch
    update_attributes(api_client.get('applications/current', {:definition => true}, {:cache_key => self.class.cache_key}))
  rescue Tml::Exception => ex
    Tml.logger.error("Failed to load application: #{ex}")
    self
  end

  def update_attributes(attrs)
    super

    self.attributes[:languages] = []
    if hash_value(attrs, :languages)
      self.attributes[:languages] = hash_value(attrs, :languages).collect{ |l| Tml::Language.new(l.merge(:application => self)) }
    end

    self
  end

  def language(locale = nil)
    locale = nil if locale.strip == ''

    locale ||= default_locale || Tml.config.default_locale
    @languages_by_locale ||= {}
    @languages_by_locale[locale] ||= api_client.get(
      "languages/#{locale}",
      {:definition => true},
      {
        :class => Tml::Language,
        :attributes => {:locale => locale, :application => self},
        :cache_key => Tml::Language.cache_key(locale)
      }
    )
  rescue Tml::Exception => e
    Tml.logger.error(e)
    Tml.logger.error(e.backtrace)
    @languages_by_locale[locale] = Tml.config.default_language
  end

  def current_language(locale)
    locale = locale.gsub('_', '-')
    lang = language(locale)
    lang ||= language(locale.split('-').first) if locale.index('-')
    lang ||= Tml.config.default_language
    lang
  end

  # Mostly used for testing
  def add_language(new_language)
    @languages_by_locale ||= {}
    return @languages_by_locale[new_language.locale] if @languages_by_locale[new_language.locale]
    new_language.application = self
    self.languages << new_language
    @languages_by_locale[new_language.locale] = new_language
    new_language
  end

  def locales
    @locales ||= languages.collect{|lang| lang.locale}
  end

  def tools
    @attributes[:tools] || {}
  end

  def url_for(path)
    "#{tools['assets']}#{path}"
  end

  def source(source, locale)
    self.sources ||= {}
    self.sources[source] ||= Tml::Source.new(
      :application => self,
      :source => source
    ).fetch_translations(locale)
  end

  def component(key, register = true)
    key = key.key if key.is_a?(Tml::Component)

    return self.components[key] if self.components[key]
    return nil unless register

    self.components[key] ||= api_client.post('components/register', {:component => key}, {:class => Tml::Component, :attributes => {:application => self}})
  end

  def register_missing_key(source_key, tkey)
    return if Tml.cache.read_only? and not Tml.session.inline_mode?

    @missing_keys_by_sources ||= {}
    @missing_keys_by_sources[source_key] ||= {}
    @missing_keys_by_sources[source_key][tkey.key] ||= tkey
    submit_missing_keys if Tml.config.submit_missing_keys_realtime
  end

  def register_keys(keys)
    params = []
    keys.each do |source_key, keys|
      next unless keys.values.any?
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

  def featured_languages
    @featured_languages ||= begin
      locales = api_client.get('applications/current/featured_locales', {}, {:cache_key => 'featured_locales'})
      (locales.nil? or locales.empty?) ? [] : languages.select{|l| locales.include?(l.locale)}
    end
  rescue
    []
  end
 
  def translators
    @translators ||= api_client.get('applications/current/translators', {}, {:class => Tml::Translator, :attributes => {:application => self}})
  rescue
    []
  end

  def reset_translation_cache
    self.sources = {}
    self.translations = {}
    @languages_by_locale      = nil
    @missing_keys_by_sources  = nil
  end

  def fetch_translations(locale)
    self.translations ||= {}
    self.translations[locale] ||= begin
      results = Tml.cache.fetch(Tml::Application.translations_cache_key(locale)) do
        data = {}
        unless Tml.cache.read_only?
          api_client.paginate('applications/current/translations', :per_page => 1000) do |translations|
            data.merge!(translations)
          end
        end
        data
      end

      translations_by_key = {}
      results.each do |key, data|
        translations_data = data.is_a?(Hash) ? data['translations'] : data
        translations_by_key[key] = translations_data.collect do |t|
          Tml::Translation.new(
            :locale => t['locale'] || locale,
            :label => t['label'],
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
    @api_client ||= Tml::Api::Client.new(:application => self)
  end

  def postoffice
    @postoffice ||= Tml::Api::PostOffice.new(:application => self)
  end

end
