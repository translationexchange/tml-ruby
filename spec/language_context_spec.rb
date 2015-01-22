# encoding: UTF-8

require 'spec_helper'

describe Tml::LanguageContext do

  before :all do
    @app = init_application
    @english = @app.language('en')
    @russian = @app.language('ru')
  end

  describe "initialize" do
    it "sets attributes" do
      expect(Tml::LanguageContext.attributes).to eq([:language, :keyword, :description, :default_key, :token_expression, :variables, :token_mapping, :keys, :rules])
    end
  end

  describe "finding context" do
    it "should return correct context" do
      #@user = stub_object(:first_name => "Mike", :gender => "male")
      #@translator = stub_object(:name => "Mike", :user => @user, :gender => "male")

      expect(@russian.context_by_keyword("date").keyword).to eq("date")
    end
  end

  describe "matching tokens" do
    it "should identify the right tokens" do
      @context = Tml::LanguageContext.new(
          :language           =>     @english,
          :keyword            =>      "numeric",
          :token_expression   => '/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/',
          :variables          => ['@n'],
          :description        =>   "Numeric language context"
      )

      expect(@context.token_expression).to eq(/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/)
      expect(@context.applies_to_token?("num")).to be_truthy
      expect(@context.applies_to_token?("num1")).to be_truthy
      expect(@context.applies_to_token?("profile_num1")).to be_truthy
      expect(@context.applies_to_token?("profile_num21")).to be_truthy
      expect(@context.applies_to_token?("profile")).to be_falsey
      expect(@context.applies_to_token?("num_years")).to be_truthy
      expect(@context.applies_to_token?("count1")).to be_truthy
      expect(@context.applies_to_token?("count2")).to be_truthy
    end
  end

  describe "gender rules" do
    describe "loading variables" do
      it "should return assigned variables" do
        context = Tml::LanguageContext.new(
            :language           => @english,
            :keyword            => "gender",
            :token_expression   => '/.*(profile|user|actor|target)(\d)*$/',
            :variables          => ['@gender'],
            :description        => "Gender language context"
        )

        obj = double(:gender => "male")
        Tml.config.stub(:context_rules) {
          {
              "gender" => {
                  "variables" => {
                      "@gender" => "gender",
                  }
              }
          }
        }
        expect(context.vars(obj)).to eq({"@gender" => "male"})

        Tml.config.stub(:context_rules) {
          {
              :gender => {
                  :variables => {
                      "@gender" => "gender",
                  }
              }
          }
        }
        expect(context.vars(obj)).to eq({"@gender" => "male"})
        expect(context.vars({:object => obj})).to eq({"@gender" => "male"})
        expect(context.vars({:gender => "male"})).to eq({"@gender" => "male"})
        expect(context.vars(:object => {:gender => "male"})).to eq({"@gender" => "male"})

        Tml.config.stub(:context_rules) {
          {
              "gender" => {
                  "variables" => {
                      "@gender" => lambda{|obj| obj.gender},
                  }
              }
          }
        }
        expect(context.vars(obj)).to eq({"@gender" => "male"})
      end
    end

    describe "evaluate rules" do
      it "should return matching rule" do
        context = Tml::LanguageContext.new(
            :language           => @english,
            :keyword            => "gender",
            :token_expression   => '/.*(profile|user|actor|target)(\d)*$/',
            :variables          => ['@gender'],
            :description        => "Gender language context",
            :rules              => {
              :male        => {:language_context => @context, :keyword => "male", :conditions => "(= 'male' @gender)"},
              :female      => {:language_context => @context, :keyword => "female", :conditions => "(= 'female' @gender)"},
              :other       => {:language_context => @context, :keyword => "other"}
            }
        )

        Tml.config.stub(:context_rules) {
          {
              "gender" => {
                  "variables" => {
                      "@gender" => "gender",
                  }
              }
          }
        }

        expect(context.fallback_rule.keyword).to eq(:other)

        expect(context.find_matching_rule(double(:gender => "male")).keyword).to eq(:male)
        expect(context.find_matching_rule(double(:gender => "female")).keyword).to eq(:female)
        expect(context.find_matching_rule(double(:gender => "unknown")).keyword).to eq(:other)

        # unknown goes before other
        context.rules[:unknown] = Tml::LanguageContextRule.new(:language_context => @context, :keyword => "unknown", :conditions => "(&& (!= 'male' @gender) (!= 'female' @gender))")
        expect(context.find_matching_rule(double(:gender => "unknown")).keyword).to eq('unknown')
      end
    end
  end

  describe "genders rules" do
    before(:each) do
      @context = Tml::LanguageContext.new(
          :language             => @english,
          :keyword              => "genders",
          :token_expression     => '/.*(profiles|users|actors|targets)(\d)*$/',
          :variables            => ['@genders', '@count'],
          :description          =>  "Language context for list of users"
      )

      Tml.config.stub(:context_rules) {
        {
            "genders" => {
                "variables" => {
                    "@genders" => lambda{|list|
                      list.collect{|u| u.gender}
                    },
                    "@count" => lambda{|list| list.count},
                }
            }
        }
      }
    end

    describe "loading variables" do
      it "should return assigned variables" do
        obj = [double(:gender => "male"), double(:gender => "female")]
        expect(@context.vars(obj)).to eq({"@genders" => ["male", "female"], "@count" => 2})
      end
    end

    describe "evaluate rules" do
      it "should return matching rule" do
        Tml.config.stub(:context_rules) {
          {
              "genders" => {
                  "variables" => {
                      "@genders" => lambda{|list| list.collect{|u| u.gender}},
                  }
              }
          }
        }

        @context.rules[:one_male]    = Tml::LanguageContextRule.new(:conditions => "(&& (= 1 (count @genders)) (all @genders 'male'))")
        @context.rules[:one_female]  = Tml::LanguageContextRule.new(:conditions => "(&& (= 1 (count @genders)) (all @genders 'female'))")
        @context.rules[:one_unknown] = Tml::LanguageContextRule.new(:conditions => "(&& (= 1 (count @genders)) (all @genders 'unknown'))")
        @context.rules[:other]       = Tml::LanguageContextRule.new(:keyword => "other")

        expect(@context.find_matching_rule([double(:gender => "male")])).to eq(@context.rules[:one_male])
        expect(@context.find_matching_rule([double(:gender => "female")])).to eq(@context.rules[:one_female])
        expect(@context.find_matching_rule([double(:gender => "unknown")])).to eq(@context.rules[:one_unknown])
        expect(@context.find_matching_rule([double(:gender => "male"), double(:gender => "male")])).to eq(@context.rules[:other])

        # unknown goes before other
        @context.rules[:at_least_two] = Tml::LanguageContextRule.new(:conditions => "(> (count @genders) 1)")
        expect(@context.find_matching_rule([double(:gender => "male"), double(:gender => "male")])).to eq(@context.rules[:at_least_two])

        @context.rules.delete(:at_least_two)

        @context.rules[:all_male] = Tml::LanguageContextRule.new(:conditions => "(&& (> (count @genders) 1) (all @genders 'male'))")
        @context.rules[:all_female] = Tml::LanguageContextRule.new(:conditions => "(&& (> (count @genders) 1) (all @genders 'female'))")

        expect(@context.find_matching_rule([double(:gender => "male"), double(:gender => "male")])).to eq(@context.rules[:all_male])
        expect(@context.find_matching_rule([double(:gender => "female"), double(:gender => "female")])).to eq(@context.rules[:all_female])
        expect(@context.find_matching_rule([double(:gender => "male"), double(:gender => "female")])).to eq(@context.rules[:other])
      end
    end
  end

  describe "list rules" do
    before(:each) do
      @context = Tml::LanguageContext.new(
          :language             => @english,
          :keyword              => "list",
          :token_expression     => '/.*(list)(\d)*$/',
          :variables            => ['@count'],
          :description          =>  "Language context for lists"
      )

      Tml.config.stub(:context_rules) {
        {
            "list" => {
                "variables" => {
                    "@count" => "count",
                }
            }
        }
      }
    end

    describe "loading variables" do
      it "should return assigned variables" do
        obj = ["apple", "banana"]
        expect(@context.vars(obj)).to eq({"@count" => 2})
      end
    end

    describe "evaluate rules" do
      it "should return matching rule" do
        @context.rules[:one] = Tml::LanguageContextRule.new(:conditions => "(= 1 @count)")
        @context.rules[:two] = Tml::LanguageContextRule.new(:conditions => "(= 2 @count)")
        @context.rules[:other] = Tml::LanguageContextRule.new(:keyword => "other")

        expect(@context.find_matching_rule(["apple"])).to eq(@context.rules[:one])
        expect(@context.find_matching_rule(["apple", "banana"])).to eq(@context.rules[:two])
        expect(@context.find_matching_rule(["apple", "banana", "grapes"])).to eq(@context.rules[:other])
      end
    end
  end

  describe "numeric rules" do
    before(:each) do
      @context = Tml::LanguageContext.new(
          :language             => @english,
          :keyword              => "numeric",
          :token_expression     => '/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/',
          :variables            => ['@n'],
          :description          =>  "Language context for numbers"
      )

      Tml.config.stub(:context_rules) {
        {
          "numeric" => {
            "token_expression" => '/.*(count|num|age|hours|minutes|years|seconds)(\d)*$/',
            "variables" => {
              "@n" => "to_i",
            }
          }
        }
      }
    end

    describe "loading variables" do
      it "should return assigned variables" do
        obj = double(:to_i => 10)
        expect(@context.vars(obj)).to eq({"@n" => 10})

        obj = 15
        expect(@context.vars(obj)).to eq({"@n" => 15})
      end
    end

    describe "evaluate rules" do
      it "should return matching rule" do
        @context.rules[:one] = Tml::LanguageContextRule.new(:conditions => "(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))", :description => "{n} mod 10 is 1 and {n} mod 100 is not 11", :examples => "1, 21, 31, 41, 51, 61...")
        @context.rules[:few] = Tml::LanguageContextRule.new(:conditions => "(&& (in '2..4' (mod @n 10)) (not (in '12..14' (mod @n 100))))", :description => "{n} mod 10 in 2..4 and {n} mod 100 not in 12..14", :examples => "2-4, 22-24, 32-34...")
        @context.rules[:many] = Tml::LanguageContextRule.new(:conditions => "(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))", :description => "{n} mod 10 is 0 or {n} mod 10 in 5..9 or {n} mod 100 in 11..14", :examples => "0, 5-20, 25-30, 35-40...")

        expect(@context.find_matching_rule(1)).to eq(@context.rules[:one])
        expect(@context.find_matching_rule(2)).to eq(@context.rules[:few])
        expect(@context.find_matching_rule(0)).to eq(@context.rules[:many])
      end
    end
  end

  describe "date rules" do
    before(:each) do
      @context = Tml::LanguageContext.new(
          :language             => @english,
          :keyword              => "date",
          :token_expression     => '/.*(date)(\d)*$/',
          :variables            => ['@date'],
          :description          =>  "Language context for dates"
      )

      Tml.config.stub(:context_rules) {
        {
            "date" => {
                "variables" => {
                }
            }
        }
      }
    end

    describe "loading variables" do
      it "should return assigned variables" do
        today = Date.today
        expect(@context.vars(today)).to eq({"@date" => today})
      end
    end

    describe "evaluate rules" do
      it "should return matching rule" do
        @context.rules[:present] = Tml::LanguageContextRule.new(:conditions => "(= (today) @date)")
        @context.rules[:past] = Tml::LanguageContextRule.new(:conditions => "(> (today) @date)")
        @context.rules[:future] = Tml::LanguageContextRule.new(:conditions => "(< (today) @date)")

        expect(@context.find_matching_rule(Date.today)).to eq(@context.rules[:present])
        expect(@context.find_matching_rule(Date.today - 24)).to eq(@context.rules[:past])
        expect(@context.find_matching_rule(Date.today + 24)).to eq(@context.rules[:future])
      end
    end
  end

end
