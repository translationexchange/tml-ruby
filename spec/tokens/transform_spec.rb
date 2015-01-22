# encoding: UTF-8

require 'spec_helper'

describe Tml::Tokens::Transform do
  #before do
  #  @app = init_application
  #  @english = @app.language('en')
  #  @tkey = Tml::TranslationKey.new({
  #    :label => "You have {count||message}",
  #    :application => @app,
  #    :locale => 'en'
  #  })
  #  @tlabel = @tkey.tokenized_label
  #end
  #
  #describe "initialize" do
  #  it "should parse token info" do
  #    token = @tlabel.tokens.first
  #    expect(token.class.name).to eq("Tml::Tokens::Transform")
  #    expect(token.original_label).to eq(@tlabel.label)
  #    expect(token.full_name).to eq("{count||message}")
  #    expect(token.declared_name).to eq("count||message")
  #    expect(token.name).to eq("count")
  #    expect(token.sanitized_name).to eq("{count}")
  #    expect(token.name_key).to eq(:count)
  #    expect(token.pipeless_name).to eq("count")
  #    expect(token.case_key).to be_nil
  #    expect(token.supports_cases?).to be_truthy
  #    expect(token.has_case_key?).to be_falsey
  #    expect(token.caseless_name).to eq("count")
  #
  #    expect(token.types).to be_nil
  #    expect(token.has_types?).to be_falsey
  #    expect(token.associated_rule_types).to eq([:number, :value])
  #    expect(token.language_rule_classes).to eq([Tml::Rules::Number, Tml::Rules::Value])
  #    expect(token.transformable_language_rule_classes).to eq([Tml::Rules::Number])
  #    expect(token.decoration?).to be_falsey
  #  end
  #end
  #
  #describe "substitute" do
  #  it "should substitute values" do
  #    token = @tlabel.tokens.first
  #
  #  end
  #end


end
