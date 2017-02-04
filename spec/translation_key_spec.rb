# encoding: UTF-8

require 'spec_helper'

describe Tml::TranslationKey do
  describe "#initialize" do
    before do
      @app = init_application
      @english = @app.language('en')
      @russian = @app.language('ru')
    end

    it "sets attributes" do
      expect(Tml::TranslationKey.attributes).to eq([:application, :language, :id, :key, :label, :description, :locale, :level, :translations])

      tkey = Tml::TranslationKey.new({
          :label => "Hello World",
          :application => @app
      })
      expect(tkey.locale).to eq("en")
      expect(tkey.language.locale).to eq("en")

      tkey = Tml::TranslationKey.new({
        :label => "Hello World",
        :application => @app,
        :locale => 'en'
      })

      expect(tkey.id).to be_nil
      expect(tkey.label).to eq("Hello World")
      expect(tkey.description).to be_nil
      expect(tkey.key).to eq("d541c79af1be6a05b1f16fca8b5730de")
      expect(tkey.locale).to eq("en")
      expect(tkey.language.locale).to eq("en")
      expect(tkey.has_translations_for_language?(@russian)).to be_falsey
      expect(tkey.translations_for_language(@russian)).to eq([])
    end

    it "translates labels correctly into default language" do
      tkey = Tml::TranslationKey.new(:label => "Hello World", :application => @app)
      expect(tkey.substitute_tokens("Hello World", {}, @english)).to eq("Hello World")

      tkey = Tml::TranslationKey.new(:label => "Hello {user}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user1}", {:user => "Michael"}, @english)).to eq("Hello {user1}")

      tkey = Tml::TranslationKey.new(:label => "Hello {user}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user}", {:user => "Michael"}, @english)).to eq("Hello Michael")

      tkey = Tml::TranslationKey.new(:label => "Hello {user1} and {user2}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user1} and {user2}", {:user1 => "Michael" , :user2 => "Tom"}, @english)).to eq("Hello Michael and Tom")

      tkey = Tml::TranslationKey.new(:label => "Hello {user}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user}", {:user => {:object => {:name => "Michael"}, :value => "Michael"}}, @english)).to eq("Hello Michael")

      tkey = Tml::TranslationKey.new(:label => "Hello {user}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user}", {:user => {:object => {:name => "Michael"}, :attribute => "name"}}, @english)).to eq("Hello Michael")

      tkey = Tml::TranslationKey.new(:label => "Hello {user}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user}", {:user => {:object => double(:name => "Michael"), :attribute => "name"}}, @english)).to eq("Hello Michael")

      tkey = Tml::TranslationKey.new(:label => "Hello {user1} [bold: and] {user2}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user1} [bold: and] {user2}", {:user1 => "Michael" , :user2 => "Tom"}, @english)).to eq("Hello Michael <strong>and</strong> Tom")

      tkey = Tml::TranslationKey.new(:label => "You have [link: [bold: {count}] messages]", :application => @app)
      expect(tkey.substitute_tokens("You have [link: [bold: {count}] messages]", {:count => 5, :link => {:href => "www.google.com"}}, @english)).to eq("You have <a href='www.google.com' class='' style='' title=''><strong>5</strong> messages</a>")

      tkey = Tml::TranslationKey.new(:label => "You have [link][bold: {count}] messages[/link]", :application => @app)
      expect(tkey.substitute_tokens("You have [link][bold: {count}] messages[/link]", {:count => 5, :link => {:href => "www.google.com"}}, @english)).to eq("You have <a href='www.google.com' class='' style='' title=''><strong>5</strong> messages</a>")

      user = stub_object({:first_name => "Tom", :last_name => "Anderson", :gender => "Male", :to_s => "Tom Anderson"})
      tkey = Tml::TranslationKey.new(:label => "Your name is {user.first_name}", :application => @app)
      expect(tkey.substitute_tokens("Your name is {user.first_name}", {:user => user}, @english)).to eq("Your name is Tom")
    end

    context "labels with numeric rules" do
      it "should return correct translations" do
        key = Tml::TranslationKey.new(:label => "You have {count||message}.", :application => @app)
        key.set_translations(@russian.locale, [
            Tml::Translation.new(:label => "U vas est {count} soobshenie.", :context => {"count" => {"number" => "one"}}),
            Tml::Translation.new(:label => "U vas est {count} soobsheniya.", :context => {"count" => {"number" => "few"}}),
            Tml::Translation.new(:label => "U vas est {count} soobshenii.", :context => {"count" => {"number" => "many"}}),
        ])

        expect(key.translate(@russian, {:count => 1})).to eq("U vas est 1 soobshenie.")
        expect(key.translate(@russian, {:count => 101})).to eq("U vas est 101 soobshenie.")
        expect(key.translate(@russian, {:count => 11})).to eq("U vas est 11 soobshenii.")
        expect(key.translate(@russian, {:count => 111})).to eq("U vas est 111 soobshenii.")

        expect(key.translate(@russian, {:count => 5})).to eq("U vas est 5 soobshenii.")
        expect(key.translate(@russian, {:count => 26})).to eq("U vas est 26 soobshenii.")
        expect(key.translate(@russian, {:count => 106})).to eq("U vas est 106 soobshenii.")

        expect(key.translate(@russian, {:count => 3})).to eq("U vas est 3 soobsheniya.")
        expect(key.translate(@russian, {:count => 13})).to eq("U vas est 13 soobshenii.")
        expect(key.translate(@russian, {:count => 23})).to eq("U vas est 23 soobsheniya.")
        expect(key.translate(@russian, {:count => 103})).to eq("U vas est 103 soobsheniya.")
      end
    end
  end
end
