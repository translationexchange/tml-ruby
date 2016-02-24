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

      key   = opts[:key]    || Tml.config.application[:key]
      host  = opts[:host]   || Tml.config.application[:host]
      # token = opts[:token]  || Tml.config.application[:token]
      token = opts[:access_token]

      Tml.cache.reset_version

      self.current_user = opts[:user]
      self.current_source = opts[:source] || 'index'
      self.current_locale = opts[:locale]
      self.current_translator = opts[:translator]

      # Tml.logger.debug(opts.inspect)

      self.application = Tml::Application.new(:key => key, :access_token => token, :host => host).fetch

      if self.current_translator
        self.current_translator.application = self.application
      end

      self.current_locale = preferred_locale(opts[:locale])
      self.current_language = self.application.current_language(self.current_locale)

      self
    end

    def preferred_locale(locales)
      return application.default_locale unless locales
      locales = locales.is_a?(String) ? locales.split(',') : locales
      locales.each do |locale|
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
      @application ||= Tml::Application.new(:host => Tml::Api::Client::API_HOST)
    end

    def source_language
      locale = block_option(:locale)
      locale ? application.language(locale) : application.language
    end

    def target_language
      target_locale = block_option(:target_locale)
      target_locale ? application.language(target_locale) : current_language
    end

    def inline_mode?
      current_translator and current_translator.inline?
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

  end
end
