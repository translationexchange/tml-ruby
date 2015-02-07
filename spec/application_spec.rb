# encoding: UTF-8

require 'spec_helper'

describe Tml::Application do
  describe "#configuration" do
    it "sets class attributes" do
      expect(Tml::Application.attributes).to eq([:host, :id, :key, :access_token,
                                                  :name, :description, :threshold, :default_locale, :default_level, :tools,
                                                  :features, :languages, :featured_locales, :sources, :components, :tokens,
                                                  :css, :shortcuts, :translations])
    end
  end

  describe "#initialize" do
    before do
      @app = init_application
    end

    it "loads application attributes" do
      expect(@app.key).to eq("default")
      expect(@app.name).to eq("Tml Translation Service")

      expect(@app.default_data_token('nbsp')).to eq("&nbsp;")
      expect(@app.default_decoration_token('strong')).to eq("<strong>{$0}</strong>")

      expect(@app.feature_enabled?(:language_cases)).to be_truthy
      expect(@app.feature_enabled?(:language_flags)).to be_truthy
    end

    it "loads application language" do
      expect(@app.languages.size).to eq(14)

      russian = @app.language('ru')
      expect(russian.locale).to eq('ru')
      expect(russian.contexts.keys.size).to eq(6)
      expect(russian.contexts.keys).to eq(["date", "gender", "genders", "list", "number", "value"])
    end

    it "should reset translations" do
      @app.reset_translation_cache
      expect(@app.translations).to eq({})
    end

    it "should reset translations" do
      @app.register_missing_key('test', Tml::TranslationKey.new(:application => @app, :label => "Hello"))
    end

  end


end