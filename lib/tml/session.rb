# encoding: UTF-8
#--
# Copyright (c) 2016           Translation Exchange, Inc
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

  def self.session
    Thread.current[:tml_context] ||= Tml::Session.new
  end

  class Session
    attr_accessor :application, :block_options
    attr_accessor :current_user, :current_locale, :current_language, :current_translator, :current_source

    def init(opts = {})
      return if Tml.config.disabled?

      # Tml.logger.debug(opts.inspect)

      Tml.cache.reset_version
      Tml.cache.namespace = opts[:namespace]

      init_application(opts)

      self
    end

    def init_application(opts = {})
      self.current_user = opts[:user]
      self.current_source = opts[:source] || 'index'
      self.current_locale = opts[:locale]
      self.current_translator = opts[:translator]

      app_config = Tml.config.application || {}
      self.application = Tml::Application.new(
          :key => opts[:key] || app_config[:key],
          :access_token => opts[:access_token] || opts[:token] || app_config[:token],
          :host => opts[:host] || app_config[:host],
          :cdn_host => opts[:cdn_host] || app_config[:cdn_host]
      ).fetch

      if self.current_translator
        self.current_translator.application = self.application
      end

      self.current_locale = preferred_locale(opts[:locale])
      self.current_language = self.application.current_language(self.current_locale)
    end

    def preferred_locale(locales)
      return application.default_locale unless locales
      locales = locales.is_a?(String) ? locales.split(',') : locales

      locales.each do |locale|
        locale = Tml::Language.normalize_locale(locale)
        return locale if application.locales.include?(locale)
        locale = locale.split('-').first
        return locale if application.locales.include?(locale)
      end

      application.default_locale
    end

    def reset
      self.application= nil
      self.current_user= nil
      self.current_language= nil
      self.current_translator= nil
      self.current_source= nil
      self.block_options= nil
    end

    def current_language
      @current_language ||= Tml.config.default_language
    end

    def application
      @application ||= Tml::Application.new
    end

    def source_language
      locale = block_option(:locale)
      locale ? application.language(locale) : application.language
    end

    def target_language
      target_locale = block_option(:target_locale)
      language = (target_locale ? application.language(target_locale) : current_language)
      language || Tml.config.default_language
    end

    def inline_mode?
      current_translator and current_translator.inline?
    end

    def translate(label, description = '', tokens = {}, options = {})
      params = Tml::Utils.normalize_tr_params(label, description, tokens, options)
      return params[:label] if params[:label].tml_translated?

      params[:options][:caller] ||= caller(1, 1)

      if Tml.config.disabled?
        return Tml.config.default_language.translate(params[:label], params[:tokens], params[:options]).tml_translated
      end

      # Translate individual sentences
      if params[:options][:split]
        text = params[:label]
        sentences = Tml::Utils.split_sentences(text)
        sentences.each do |sentence|
          text = text.gsub(sentence, target_language.translate(sentence, params[:description], params[:tokens], params[:options]))
        end
        return text.tml_translated
      end

      target_language.translate(params).tml_translated
    rescue Tml::Exception => ex
      #pp ex, ex.backtrace
      Tml.logger.error(ex.message)
      #Tml.logger.error(ex.message + "\n=> " + ex.backtrace.join("\n=> "))
      label
    end

    #########################################################
    ## Block Options
    #########################################################

    def block_option(key, lookup = true)
      if lookup
        block_options_queue.reverse.each do |options|
          value = options[key.to_s] || options[key.to_sym]
          return value if value
        end
        return nil
      end
      block_options[key]
    end

    def push_block_options(opts)
      block_options_queue.push(opts)
    end

    def pop_block_options
      return unless @block_options
      @block_options.pop
    end

    def block_options_queue
      @block_options ||= []
    end

    def block_options
      block_options_queue.last || {}
    end

    def with_block_options(opts)
      push_block_options(opts)
      if block_given?
        ret = yield
      end
      pop_block_options
      ret
    end
    alias_method :with_options, :with_block_options

  end
end
