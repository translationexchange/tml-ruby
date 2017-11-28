# encoding: UTF-8
#--
# Copyright (c) 2017 Translation Exchange, Inc
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

require 'spec_helper'

describe Tml::Application do
  describe '#configuration' do
    it 'sets class attributes' do
      expect(Tml::Application.attributes).to eq([:host, :cdn_host, :id, :key, :access_token,
                                                  :name, :description, :threshold, :default_locale, :default_level,
                                                  :features, :languages, :languages_by_locale, :sources, :sources_by_key, :tokens,
                                                  :css, :shortcuts, :translations, :extensions, :ignored_keys])
    end
  end

  describe '#initialize' do
    before do
      @app = init_application
    end

    it 'should have correct cache key' do
      expect(Tml::Application.cache_key).to eq('application')
      expect(Tml::Application.translations_cache_key('ru')).to eq('ru/translations')
    end

    it 'should have correct CDN and API urls' do
      expect(@app.host).to eq(Tml::Application::API_HOST)
      expect(@app.cdn_host).to eq(Tml::Application::CDN_HOST)
    end

    it 'loads application attributes' do
      expect(@app.key).to eq('default')
      expect(@app.name).to eq('Tml Translation Service')

      expect(@app.default_data_token('nbsp')).to eq('&nbsp;')
      expect(@app.default_decoration_token('strong')).to eq('<strong>{$0}</strong>')

      expect(@app.feature_enabled?(:language_cases)).to be_truthy
      expect(@app.feature_enabled?(:language_flags)).to be_truthy
    end

    it 'loads application language' do
      expect(@app.languages.size).to eq(15)

      russian = @app.language('ru')
      expect(russian.locale).to eq('ru')
      expect(russian.contexts.keys.size).to eq(6)
      expect(russian.contexts.keys).to eq(%w(date gender genders list number value))
    end

    it 'should reset translations' do
      @app.reset_translation_cache
      expect(@app.translations).to eq({})
    end

    it 'should reset translations' do
      @app.register_missing_key('test', Tml::TranslationKey.new(:application => @app, :label => 'Hello'))
    end

    it 'should return valid locale' do
      app = Tml::Application.new
      expect(app.default_locale).to eq('en')
      expect(@app.default_locale).to eq('en')

      expect(@app.supported_locale('en')).to eq('en')
      expect(@app.supported_locale('en-US')).to eq('en')
      expect(@app.supported_locale('ru-ru')).to eq('ru')
      expect(@app.supported_locale('de')).to eq('de')
      expect(@app.supported_locale('de-de')).to eq('de-DE')
      expect(@app.supported_locale('de-DE')).to eq('de-DE')
      expect(@app.supported_locale('it')).to eq('en')
    end

  end
end