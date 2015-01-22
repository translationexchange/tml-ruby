# encoding: UTF-8

require 'spec_helper'

describe Tml::Translation do
  describe "initialize" do
    before do
      @app = init_application
      @english = @app.language('en')
      @russian = @app.language('ru')
    end

    it "sets attributes" do
      expect(Tml::Translation.attributes).to eq([:translation_key, :language, :locale, :label, :context, :precedence])

      t = Tml::Translation.new(:label => "You have {count||message}", :context => {"count" => {"number" => "one"}}, :language => @russian)

      [1, 101, 1001].each do |count|
        expect(t.matches_rules?(:count => count)).to be_truthy
      end

    end
  end
end
