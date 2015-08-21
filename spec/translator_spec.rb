# encoding: UTF-8

require 'spec_helper'

describe Tml::Translator do
  describe "#initialize" do
    it "features" do
      translator = Tml::Translator.new({'features' => {'test' => true}})
      expect(translator.feature_enabled?(:test)).to be_truthy
    end
  end
end
