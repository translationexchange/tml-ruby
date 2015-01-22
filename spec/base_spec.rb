# encoding: UTF-8

require 'spec_helper'

describe Tml::Base do
  describe "hash value method" do
    it "must return correct values" do
      expect(Tml::Base.hash_value({"a" => "b"}, "a")).to eq("b")
      expect(Tml::Base.hash_value({:a => "b"}, "a")).to eq("b")
      expect(Tml::Base.hash_value({:a => "b"}, :a)).to eq("b")
      expect(Tml::Base.hash_value({"a" => "b"}, :a)).to eq("b")

      expect(Tml::Base.hash_value({"a" => {:b => "c"}}, "a.b")).to eq("c")
      expect(Tml::Base.hash_value({:a => {:b => "c"}}, "a.b")).to eq("c")
      expect(Tml::Base.hash_value({:a => {:b => "c"}}, "a.d")).to be_nil
      expect(Tml::Base.hash_value({:a => {:b => {:c => :d}}}, "a.b.c")).to eq(:d)
    end
  end
end
