# encoding: UTF-8

require 'spec_helper'

describe Tml::LanguageCaseRule do
  describe "initialize" do
    it "sets attributes" do
      expect(Tml::LanguageCaseRule.attributes).to eq([:language_case, :id, :description, :examples, :conditions, :conditions_expression, :operations, :operations_expression])
    end
  end

  describe "evaluating simple rules without genders" do
    it "should result in correct substitution" do
      @rule = Tml::LanguageCaseRule.new(
        :conditions => "(match '/s$/' @value)",
        :operations => "(append \"'\" @value)"
      )

      expect(@rule.evaluate("Michael")).to be_falsey
      expect(@rule.evaluate("Anna")).to be_falsey

      expect(@rule.evaluate("friends")).to be_truthy
      expect(@rule.apply("friends")).to eq("friends'")

      @rule = Tml::LanguageCaseRule.new(
        :conditions => "(not (match '/s$/' @value))",
        :operations => "(append \"'s\" @value)"
      )

      expect(@rule.evaluate("Michael")).to be_truthy
      expect(@rule.apply("Michael")).to eq("Michael's")

      expect(@rule.evaluate("Anna")).to be_truthy
      expect(@rule.apply("Anna")).to eq("Anna's")

      expect(@rule.evaluate("friends")).to be_falsey

      @rule = Tml::LanguageCaseRule.new(
          :conditions => "(= '1' @value))",
          :operations => "(quote 'first')"
      )

      expect(@rule.evaluate('2')).to be_falsey
      expect(@rule.evaluate('1')).to be_truthy
      expect(@rule.apply('1')).to eq("first")

      @rule = Tml::LanguageCaseRule.new(
          :conditions => "(match '/(0|4|5|6|7|8|9|11|12|13)$/' @value))",
          :operations => "(append 'th' @value)"
      )

      expect(@rule.apply('4')).to eq("4th")
      expect(@rule.apply('15')).to eq("15th")
    end
  end

end