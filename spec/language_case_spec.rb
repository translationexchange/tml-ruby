# encoding: UTF-8

require 'spec_helper'

describe Tml::LanguageCase do
  before do
    @app = init_application
    @english = @app.language('en')
    @russian = @app.language('ru')
  end

  describe "initialize" do
    it "sets attributes" do
      expect(Tml::LanguageCase.attributes).to eq([:language, :id, :keyword, :latin_name, :native_name, :description, :application, :rules])
    end
  end

  describe "apply case" do
    it "should return correct data" do
      lcase = Tml::LanguageCase.new(
          :language     => @english,
          :keyword      => "pos",
          :latin_name   => "Possessive",
          :native_name  => "Possessive",
          :description  => "Used to indicate possession (i.e., ownership). It is usually created by adding 's to the word",
          :application  => "phrase"
      )

      lcase.rules << Tml::LanguageCaseRule.new(:conditions => "(match '/s$/' @value)", :operations => "(append \"'\" @value)")
      lcase.rules << Tml::LanguageCaseRule.new(:conditions => "(not (match '/s$/' @value))", :operations => "(append \"'s\" @value)")
      expect(lcase.apply("Michael")).to eq("Michael's")
    end

    it "should correctly process default cases" do
      possessive = @english.case_by_keyword('pos')
      expect(possessive.apply("Michael")).to eq("Michael's")


      plural = @english.case_by_keyword('plural')

      expect(plural.apply("fish")).to eq("fish")
      expect(plural.apply("money")).to eq("money")

      # irregular
      expect(plural.apply("move")).to eq("moves")

      # plurals
      expect(plural.apply("quiz")).to eq("quizzes")
      expect(plural.apply("wife")).to eq("wives")

      singular = @english.case_by_keyword('singular')
      expect(singular.apply("quizzes")).to eq("quiz")
      expect(singular.apply("cars")).to eq("car")
      expect(singular.apply("wives")).to eq("wife")
    end
  end

end