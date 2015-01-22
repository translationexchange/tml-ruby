# encoding: UTF-8

require 'spec_helper'

describe Tml::Utils do
  describe "helper methods" do
    it "should return correct values" do

      expect(
        Tml::Utils.normalize_tr_params("Hello {user}", "Sample label", {:user => "Michael"}, {})
      ).to eq(
        {:label=>"Hello {user}", :description=>"Sample label", :tokens=>{:user=>"Michael"}, :options=>{}}
      )

      expect(
        Tml::Utils.normalize_tr_params("Hello {user}", {:user => "Michael"}, nil, nil)
      ).to eq(
        {:label=>"Hello {user}", :description=>nil, :tokens=>{:user=>"Michael"}, :options=>nil}
      )

      expect(
        Tml::Utils.normalize_tr_params("Hello {user}", {:user => "Michael"}, {:skip_decoration => true}, nil)
      ).to eq(
        {:label=>"Hello {user}", :description=>nil, :tokens=>{:user=>"Michael"}, :options=>{:skip_decoration=>true}}
      )

      expect(
        Tml::Utils.normalize_tr_params({:label=>"Hello {user}", :description=>"Sample label", :tokens=>{:user=>"Michael"}, :options=>{}}, nil, nil, nil)
      ).to eq(
        {:label=>"Hello {user}", :description=>"Sample label", :tokens=>{:user=>"Michael"}, :options=>{}}
      )

      expect(Tml::Utils.guid.class).to be(String)
    end

    it "should correctly split by sentence" do

      expect(
          Tml::Utils.split_by_sentence("Hello World")
      ).to eq(
          ["Hello World"]
      )

      expect(
          Tml::Utils.split_by_sentence("This is the first sentence. Followed by the second one.")
      ).to eq(
           ["This is the first sentence.", "Followed by the second one."]
       )

    end

    it "should correctly sign and verify signature" do
      data = {"name" => "Michael"}
      key = "abc"

      request =  Tml::Utils.sign_and_encode_params(data, key)
      result = Tml::Utils.decode_and_verify_params(request, key)
      expect(result["name"]).to eq(data["name"])
    end

  end
end
