# encoding: UTF-8

require 'spec_helper'

describe Tml::Tokens::Data do
  before do
    @app = init_application
    @english = @app.language('en')
    @tkey = Tml::TranslationKey.new({
      :label => "Hello {user}",
      :application => @app,
      :locale => 'en'
    })
    @token = @tkey.data_tokens.first
  end

  describe "initialize" do
    it "should parse data token" do
      expect(@token.class.name).to eq("Tml::Tokens::Data")
      expect(@token.context_keys).to eq([])
    end
  end

  describe "substitute" do
    it "should substitute values" do
      user = stub_object({:first_name => "Tom", :last_name => "Anderson", :gender => "Male", :to_s => "Tom Anderson"})
      user.stub(:last_name_with_prefix) {|prefix| "#{prefix} #{user.last_name}"}

      # tr("Hello {user}", "", {:user => current_user}}
      expect(@token.token_value(user, @english)).to eq(user.to_s)

      # tr("Hello {user}", "", {:user => [current_user, current_user.name]}}
      expect(@token.token_value([user, user.first_name], @english)).to eq(user.first_name)

      # tr("Hello {user}", "", {:user => [current_user, :name]}}
      expect(@token.token_value([user, :first_name], @english)).to eq(user.first_name)

      # tr("Hello {user}", "", {:user => {:object => current_user, :value => current_user.name}]}}
      expect(@token.token_value({:object => user, :value => user.to_s}, @english)).to eq(user.to_s)

      # tr("Hello {user}", "", {:user => {:object => current_user, :attribute => :first_name}]}}
      expect(@token.token_value({:object => user, :attribute => :first_name}, @english)).to eq(user.first_name)
      expect(@token.token_value({:object => {:first_name => "Michael"}, :attribute => :first_name}, @english)).to eq("Michael")
    end

    it "should perform complete substitution" do
      user = stub_object({:first_name => "Tom", :last_name => "Anderson", :gender => "Male", :to_s => "Tom Anderson"})
      user.stub(:last_name_with_prefix) {|prefix| "#{prefix} #{user.last_name}"}

      [
        {:user => user},                                                                        "Hello Tom Anderson",
        {:user => [user, user.first_name]},                                                     "Hello Tom",
        {:user => [user, :first_name]},                                                         "Hello Tom",
        {:user => {:object => user, :value => user.to_s}},                                      "Hello Tom Anderson",
        {:user => {:object => user, :attribute => :first_name}},                                "Hello Tom",
        {:user => {:object => {:first_name => "Michael"}, :attribute => :first_name}},          "Hello Michael"
      ].each_slice(2).to_a.each do |pair|
        expect(@token.substitute(@tkey.label, pair.first, @english)).to eq(pair.last)
      end

    end

    it "should substitute token with array values" do
      tkey = Tml::TranslationKey.new({
        :label => "Hello {users}",
        :application => @app,
        :locale => 'en'
      })
      token = tkey.data_tokens.first

      users = []
      1.upto(6) do |i|
        users << stub_object({:first_name => "First name #{i}", :last_name => "Last name #{i}", :gender => "Male"})
      end

      Tml.session.with_block_options(:dry => true) do
        expect(token.token_value([users, :first_name], @english)).to match("2 others")

        expect(token.token_value([users, :first_name, {
            :description => "List joiner",
            :limit => 4,
            :separator => ", ",
            :joiner => 'and',
            :less => '{laquo} less',
            :expandable => false,
            :collapsable => true
        }], @english)).to eq("First name 1, First name 2, First name 3, First name 4 and 2 others")

        expect(token.token_value([users, :first_name, {
            :description => "List joiner",
            :limit => 10,
            :separator => ", ",
            :joiner => 'and',
            :less => '{laquo} less',
            :expandable => false,
            :collapsable => true
        }], @english)).to eq("First name 1, First name 2, First name 3, First name 4, First name 5 and First name 6")

        expect(token.token_value([users, :first_name, {
            :joiner => 'or',
            :expandable => false,
        }], @english)).to eq("First name 1, First name 2, First name 3, First name 4 or 2 others")

        expect(token.token_value([users, :first_name, {
            :limit => 2,
            :joiner => 'or',
            :expandable => false,
        }], @english)).to eq("First name 1, First name 2 or 4 others")

      end
    end
  end

end
