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

  def self.session
    Thread.current[:session] ||= Tml::Session.new
  end

  class Session
    attr_accessor :application, :block_options
    attr_accessor :current_user, :current_locale, :current_language, :current_translator, :current_source

    def init(opts = {})
      return unless Tml.config.enabled? and Tml.config.application

      host = opts[:host] || Tml.config.application[:host]

      Tml.cache.reset_version

      self.current_user = opts[:user]
      self.current_source = opts[:source] || 'index'
      self.current_locale = opts[:locale]
      self.current_translator = opts[:translator]

      self.application = Tml::Application.new(:host => host).fetch

      # if inline mode don't use any app cache
      # if inline_mode?
      #   self.application = self.application.dup
      #   self.application.reset_translation_cache
      # end

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
      (@block_options || []).reverse.each do |opts|
        return application.language(opts[:locale]) unless opts[:locale].nil?
      end

      application.language
    end

    def target_language
      (@block_options || []).reverse.each do |opts|
        return application.language(opts[:target_locale]) unless opts[:target_locale].nil?
      end

      current_language
    end

    def inline_mode?
      current_translator and current_translator.inline?
    end

    #########################################################
    ## Block Options
    #########################################################

    def push_block_options(opts)
      (@block_options ||= []).push(opts)
    end

    def pop_block_options
      return unless @block_options
      @block_options.pop
    end

    def block_options
      (@block_options ||= []).last || {}
    end

    def block_options_queue
      @block_options
    end

    def with_block_options(opts)
      push_block_options(opts)
      if block_given?
        ret = yield
      end
      pop_block_options
      ret
    end

    def current_source_from_block_options
      arr = @block_options || []
      arr.reverse.each do |opts|
        return application.source_by_key(opts[:source]) unless opts[:source].blank?
      end
      nil
    end

  end
end
