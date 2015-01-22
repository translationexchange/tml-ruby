# encoding: UTF-8

require 'spec_helper'

describe Tml::LanguageContextRule do

  describe "initialize" do
    it "sets attributes" do
      expect(Tml::LanguageContextRule.attributes).to eq([:language_context, :keyword, :description, :examples, :conditions, :conditions_expression])
    end
  end

  describe "finding fallback rules" do
    it "should return fallback rule" do
      rule = Tml::LanguageContextRule.new(:keyword => "one", :conditions => "(= 1 @n)", :examples => "1")
      expect(rule.fallback?).to be_falsey

      rule = Tml::LanguageContextRule.new(:keyword => "other", :examples => "0, 2-999; 1.2, 2.07...")
      expect(rule.fallback?).to be_truthy
    end
  end

  describe "evaluating rules" do
    it "should return correct results" do
      rule = Tml::LanguageContextRule.new(:keyword => "one", :conditions => "(= 1 @n)", :examples => "1")
      expect(rule.evaluate).to be_falsey
      expect(rule.evaluate({"@n" => 1})).to be_truthy
      expect(rule.evaluate({"@n" => 2})).to be_falsey
      expect(rule.evaluate({"@n" => 0})).to be_falsey

      one = Tml::LanguageContextRule.new(:keyword => "one", :conditions => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))", :description => "{n} mod 10 is 1 and {n} mod 100 is not 11", :examples => "1, 21, 31, 41, 51, 61...")
      few = Tml::LanguageContextRule.new(:keyword => "few", :conditions => "(&& (in '2..4' (mod @n 10)) (not (in '12..14' (mod @n 100))))", :description => "{n} mod 10 in 2..4 and {n} mod 100 not in 12..14", :examples => "2-4, 22-24, 32-34...")
      many = Tml::LanguageContextRule.new(:keyword => "many", :conditions => "(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))", :description => "{n} mod 10 is 0 or {n} mod 10 in 5..9 or {n} mod 100 in 11..14", :examples => "0, 5-20, 25-30, 35-40...")

      {
          [1, 21, 31, 101, 121] => one,
          [2, 3, 4, 22, 23, 24, 102, 103, 104] => few,
          [0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 17, 20, 25, 26, 28, 30, 35, 36, 38, 39, 40] => many
      }.each do |vals, rule|
        vals.each do |val|
          vars = {"@n" => val}
          expect(rule.evaluate(vars)).to be_truthy
        end
      end

      {
          [2, 3, 4, 9] => one,
          [5, 6, 7, 8, 9] => few,
          [1, 2, 3, 4] => many
      }.each do |vals, rule|
        vals.each do |val|
          vars = {"@n" => val}
          expect(rule.evaluate(vars)).to be_falsey
        end
      end

      one_male = Tml::LanguageContextRule.new(:keyword => "one_male", :conditions => "(&& (= 1 (count @genders)) (all @genders 'male'))", :description => "List contains one male user")
      one_female = Tml::LanguageContextRule.new(:keyword => "one_female", :conditions => "(&& (= 1 (count @genders)) (all @genders 'female'))", :description => "List contains one female user")
      one_unknown = Tml::LanguageContextRule.new(:keyword => "one_unknown", :conditions => "(&& (= 1 (count @genders)) (all @genders 'unknown'))", :description => "List contains one user with unknown gender")
      many = Tml::LanguageContextRule.new(:keyword => "many", :conditions => "(> (count @genders) 1)", :description => "List contains two or more users")

      expect(one_male.evaluate({"@genders" => ["male"]})).to be_truthy
      expect(one_male.evaluate({"@genders" => ["male", "male"]})).to be_falsey

      expect(one_female.evaluate({"@genders" => ["female"]})).to be_truthy
      expect(many.evaluate({"@genders" => ["female", "male"]})).to be_truthy

      expect(one_unknown.evaluate({"@genders" => ["unknown"]})).to be_truthy

      many_male = Tml::LanguageContextRule.new(:keyword => "one", :conditions => "(&& (> (count @genders) 1) (all @genders 'male'))", :description => "List contains at least two users, all male")
      expect(many_male.evaluate({"@genders" => ["male", "male"]})).to be_truthy
    end
  end

end
