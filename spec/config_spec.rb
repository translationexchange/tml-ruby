# encoding: UTF-8

require 'spec_helper'

describe Tml::Config do
  describe "loading defaults" do
    it "should load correct values" do
      expect(Tml.config.logger[:enabled]).to be_falsey
      expect(Tml.config.enabled?).to be_truthy
      expect(Tml.config.default_locale).to eq("en")
      expect(Tml.config.cache[:enabled]).to be_falsey
      expect(Tml.config.logger[:path]).to eq("./log/tml.log")
      expect(Tml.config.cache[:adapter]).to eq("memcache")
    end
  end

  describe "configuring settings" do
    it "should preserve changes" do
      expect(Tml.config.default_locale).to eq("en")
      Tml.configure do |config|
        config.default_locale= 'ru'
      end
      expect(Tml.config.default_locale).to eq("ru")

      Tml.configure do |config|
        config.default_locale= 'en'
      end
      expect(Tml.config.default_locale).to eq("en")
    end
  end

end
