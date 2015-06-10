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

class Tml::Language < Tml::Base
  belongs_to  :application
  attributes  :locale, :name, :english_name, :native_name, :right_to_left, :flag_url
  has_many    :contexts, :cases

  def self.cache_key(locale)
    File.join(locale, 'language')
  end

  def fetch
    update_attributes(application.api_client.get("language/#{locale}", {}, {:cache_key => self.class.cache_key(locale)}))
  rescue Tml::Exception => ex
    Tml.logger.error("Failed to load language: #{ex}")
    self
  end

  def update_attributes(attrs)
    super

    self.attributes[:contexts] = {}
    if hash_value(attrs, :contexts)
      hash_value(attrs, :contexts).each do |key, context|
        self.attributes[:contexts][key] = Tml::LanguageContext.new(context.merge(:keyword => key, :language => self))
      end
    end

    self.attributes[:cases] = {}
    if hash_value(attrs, :cases)
      hash_value(attrs, :cases).each do |key, lcase|
        self.attributes[:cases][key] = Tml::LanguageCase.new(lcase.merge(:keyword => key, :language => self))
      end
    end
  end

  def context_by_keyword(keyword)
    hash_value(contexts, keyword)
  end

  def context_by_token_name(token_name)
    contexts.values.detect{|ctx| ctx.applies_to_token?(token_name)}
  end

  def case_by_keyword(keyword)
    cases[keyword]
  end

  def has_definition?
    contexts.any?
  end

  def default?
    return true unless application
    application.default_locale == locale
  end

  def dir
    right_to_left? ? 'rtl' : 'ltr'
  end

  def align(dest)
    return dest unless right_to_left?
    dest.to_s == 'left' ? 'right' : 'left'
  end

  def full_name
    return english_name if english_name == native_name
    "#{english_name} - #{native_name}"
  end

  def current_source(options)
    (options[:source] || Tml.session.block_options[:source] || Tml.session.current_source || 'undefined').to_s
  end

  #######################################################################################################
  # Translation Methods
  #
  # Note - when inline translation mode is enable, cache will not be used and translators will
  # always hit the live service to get the most recent translations
  #
  # Some cache adapters cache by source, others by key. Some are read-only, some are built on the fly.
  #
  # There are three ways to call the tr method
  #
  # tr(label, description = "", tokens = {}, options = {})
  # or
  # tr(label, tokens = {}, options = {})
  # or
  # tr(:label => label, :description => "", :tokens => {}, :options => {})
  ########################################################################################################

  def translate(label, description = nil, tokens = {}, options = {})
    params = Tml::Utils.normalize_tr_params(label, description, tokens, options)
    return params[:label] if params[:label].tml_translated?

    translation_key = Tml::TranslationKey.new({
      :application  => application,
      :label        => params[:label],
      :description  => params[:description],
      :locale       => hash_value(params[:options], :locale) || hash_value(Tml.session.block_options, :locale) || Tml.config.default_locale,
      :level        => hash_value(params[:options], :level) || hash_value(Tml.session.block_options, :level) || Tml.config.default_level,
      :translations => []
    })

    #Tml.logger.info("Translating " + params[:label] + " from: " + translation_key.locale.inspect + " to " + locale.inspect)

    params[:tokens] ||= {}
    params[:tokens][:viewing_user] ||= Tml.session.current_user

    if Tml.config.disabled? or self.locale == translation_key.locale or application.nil?
      return translation_key.substitute_tokens(
        params[:label],
        params[:tokens],
        self,
        params[:options]
      ).tml_translated
    end

    cached_translations = application.cached_translations(locale, translation_key.key)
    if cached_translations
      translation_key.set_translations(locale, cached_translations)
      return translation_key.translate(self, params[:tokens], params[:options]).tml_translated
    end

    source_key = current_source(options)

    source = application.source(source_key, locale)
    cached_translations = source.cached_translations(locale, translation_key.key)

    if cached_translations
      translation_key.set_translations(locale, cached_translations)
    else
      params[:options] ||= {}
      params[:options][:pending] = true
      application.register_missing_key(source_key, translation_key)
    end

    translation_key.translate(self, params[:tokens], params[:options]).tml_translated
  end
  alias :tr :translate

end
