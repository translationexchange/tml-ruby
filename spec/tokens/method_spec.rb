# encoding: UTF-8

require 'spec_helper'

describe Tml::Tokens::Method do
  before do
   @app = init_application
   @english = @app.language('en')
   @tkey = Tml::TranslationKey.new({
     :label => 'Hello {user.first_name}',
     :application => @app,
     :locale => 'en'
   })
   @token = @tkey.data_tokens.first
  end
  #
  #describe "initialize" do
  #  it "should parse token info" do
  #    token = @tlabel.tokens.first
  #    expect(token.class.name).to eq("Tml::Tokens::Method")
  #    expect(token.original_label).to eq(@tlabel.label)
  #    expect(token.full_name).to eq("{user.first_name}")
  #    expect(token.declared_name).to eq("user.first_name")
  #    expect(token.name).to eq("user.first_name")
  #    expect(token.sanitized_name).to eq("{user.first_name}")
  #    expect(token.name_key).to eq(:"user.first_name")
  #    expect(token.pipeless_name).to eq("user.first_name")
  #    expect(token.case_key).to be_nil
  #    expect(token.supports_cases?).to be_truthy
  #    expect(token.has_case_key?).to be_falsey
  #    expect(token.caseless_name).to eq("user.first_name")
  #
  #    expect(token.types).to be_nil
  #    expect(token.has_types?).to be_falsey
  #    expect(token.associated_rule_types).to eq([:value])
  #    expect(token.language_rule_classes).to eq([Tml::Rules::Value])
  #    expect(token.transformable_language_rule_classes).to eq([])
  #    expect(token.decoration?).to be_falsey
  #  end
  #end
  #
  describe "substitute" do
   it "should substitute values" do
     token = @tkey.data_tokens.first

     user = stub_object({:first_name => "Tom", :last_name => "Anderson", :gender => "Male", :to_s => "Tom Anderson"})

     # tr("Hello {user}", "", {:user => current_user}}
     expect(token.token_value(user, @english, {})).to eq(user.to_s)

     expect(token.object_name).to eq('user')
     expect(token.object_method_name).to eq('first_name')

     # tr("Hello {user}", "", {:user => [current_user]}}
     # expect(token.token_value([user], {}, @english)).to eq(user.to_s)
     #
     # # tr("Hello {user}", "", {:user => [current_user, current_user.name]}}
     # expect(token.token_value([user, user.first_name], {}, @english)).to eq(user.first_name)
     #
     # # tr("Hello {user}", "", {:user => [current_user, "{$0} {$1}", "param1"]}}
     # expect(token.token_value([user, "{$0} {$1}", "param1"], {}, @english)).to eq(user.to_s + " param1")
     # expect(token.token_value([user, "{$0} {$1} {$2}", "param1", "param2"], {}, @english)).to eq(user.to_s + " param1 param2")
     #
     # # tr("Hello {user}", "", {:user => [current_user, :name]}}
     # expect(token.token_value([user, :first_name], {}, @english)).to eq(user.first_name)
     #
     # # tr("Hello {user}", "", {:user => [current_user, :method_name, "param1"]}}
     # user.stub(:last_name_with_prefix) {|prefix| "#{prefix} #{user.last_name}"}
     # expect(token.token_value([user, :last_name_with_prefix, 'Mr.'], {}, @english)).to eq("Mr. Anderson")
     #
     # # tr("Hello {user}", "", {:user => [current_user, lambda{|user| user.name}]}}
     # expect(token.token_value([user, lambda{|user| user.to_s}], {}, @english)).to eq(user.to_s)
     #
     # # tr("Hello {user}", "", {:user => [current_user, lambda{|user, param1| user.name}, "param1"]}}
     # expect(token.token_value([user, lambda{|user, param1| user.to_s + " " + param1}, "extra_param1"], {}, @english)).to eq(user.to_s + " extra_param1")
     #
     # # tr("Hello {user}", "", {:user => {:object => current_user, :value => current_user.name}]}}
     # expect(token.token_value({:object => user, :value => user.to_s}, {}, @english)).to eq(user.to_s)
     #
     # # tr("Hello {user}", "", {:user => {:object => current_user, :attribute => :first_name}]}}
     # expect(token.token_value({:object => user, :attribute => :first_name}, {}, @english)).to eq(user.first_name)
     # expect(token.token_value({:object => {:first_name => "Michael"}, :attribute => :first_name}, {}, @english)).to eq("Michael")
   end
  end


end
