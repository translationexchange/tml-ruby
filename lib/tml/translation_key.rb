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

require 'digest/md5'

class Tml::TranslationKey < Tml::Base
  belongs_to :application, :language
  attributes :id, :key, :label, :description, :locale, :level, :syntax
  has_many :translations # hashed by language

  def initialize(attrs = {})
    super

    self.attributes[:key] ||= self.class.generate_key(label, description)
    self.attributes[:locale] ||= Tml.session.block_option(:locale) || (application ? application.default_locale : Tml.config.default_locale)
    self.attributes[:language] ||= application ? application.language(locale) : Tml.config.default_language
    self.attributes[:translations] = {}

    if hash_value(attrs, :translations)
      hash_value(attrs, :translations).each do |locale, translations|
        language = application.language(locale)

        self.attributes[:translations][locale] ||= []

        translations.each do |translation_hash|
          translation = Tml::Translation.new(translation_hash.merge(:translation_key => self, :locale => language.locale))
          self.attributes[:translations][locale] << translation
        end
      end
    end
  end

  def self.generate_key(label, desc = '')
    "#{Digest::MD5.hexdigest("#{label};;;#{desc}")}~"[0..-2].to_s
  end

  def has_translations_for_language?(language)
    translations and translations[language.locale] and translations[language.locale].any?
  end

  def set_translations(locale, translations)
    translations.each do |translation|
      translation.locale ||= locale
      translation.translation_key = self
      translation.language = self.application.language(translation.locale)
    end
    self.translations[locale] = translations
  end

  # switches to a new application
  def set_application(app)
    self.application = app
    translations.values.each do |locale_translations|
      locale_translations.each do |translation|
        translation.translation_key = self
        translation.language = self.application.language(translation.locale)
      end
    end
    self
  end

  def self.cache_key(locale, key)
    File.join(locale, 'keys', key)
  end

  # update translations in the key
  def update_translations(locale, data)
    set_translations(locale, application.cache_translations(
                               locale,
                               key,
                               data.is_a?(Hash) ? data['translations'] : data
                           ))
  end

  # fetch translations for a specific translation key
  def fetch_translations(locale)
    self.translations ||= {}
    return if self.translations[locale]

    # Tml.logger.debug("Fetching translations for #{label}")

    results = self.application.api_client.get(
        "translation_keys/#{self.key}/translations",
        {:locale => locale, :per_page => 10000},
        {:cache_key => Tml::TranslationKey.cache_key(locale, self.key)}
    ) || []

    update_translations(locale, results)

    self
  rescue Tml::Exception => ex
    self.translations = {}
    self
  end

  ###############################################################
  ## Translation Methods
  ###############################################################

  def translations_for_language(language)
    return [] unless self.translations
    self.translations[language.locale] || []
  end

  def find_first_valid_translation(language, token_values)
    translations = translations_for_language(language)

    translations.sort! { |x, y| x.precedence <=> y.precedence }

    translations.each do |translation|
      return translation if translation.matches_rules?(token_values)
    end

    nil
  end

  def translate(language, token_values = {}, options = {})
    if Tml.config.disabled?
      return substitute_tokens(label, token_values, language, options.merge(:fallback => false))
    end

    translation = find_first_valid_translation(language, token_values)
    decorator = Tml::Decorators::Base.decorator(options)

    if translation
      options[:locked] = translation.locked
      translated_label = substitute_tokens(translation.label, token_values, translation.language, options)
      return decorator.decorate(translated_label, translation.language, language, self, options)
    end

    translated_label = substitute_tokens(label, token_values, self.language, options)
    decorator.decorate(translated_label, self.language, language, self, options)
  end

  ###############################################################
  ## Token Substitution Methods
  ###############################################################

  # Returns an array of decoration tokens from the translation key
  def decoration_tokens
    @decoration_tokens ||= begin
      dt = Tml::Tokenizers::Decoration.new(label)
      dt.parse
      dt.tokens
    end
  end

  # Returns an array of data tokens from the translation key
  def data_tokens
    @data_tokens ||= begin
      dt = Tml::Tokenizers::Data.new(label)
      dt.tokens
    end
  end

  def data_tokens_names_map
    @data_tokens_names_map ||= begin
      map = {}
      data_tokens.each do |token|
        map[token.name] = token
      end
      map
    end
  end

  # if the translations engine is disabled
  def self.substitute_tokens(label, token_values, language, options = {})
    return label.to_s if options[:skip_substitution]
    Tml::TranslationKey.new(:label => label.to_s).substitute_tokens(label.to_s, token_values, language, options)
  end

  def substitute_tokens(translated_label, token_values, language, options = {})
    if options[:syntax] == 'xmessage'
      tokenizer = Tml::Tokenizers::XMessage.new(label)
      return tokenizer.substitute(language, token_values, options)
    end

    if Tml::Tokenizers::Decoration.required?(translated_label)
      translated_label = Tml::Tokenizers::Decoration.new(translated_label, token_values, :allowed_tokens => decoration_tokens).substitute
    end

    if Tml::Tokenizers::Data.required?(translated_label)
      translated_label = Tml::Tokenizers::Data.new(translated_label, token_values, :allowed_tokens => data_tokens_names_map).substitute(language, options)
    end

    translated_label
  end

end
