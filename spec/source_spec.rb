# encoding: UTF-8

require 'spec_helper'

describe Tml::Source do
  describe "#initialize" do
    it "helper methods" do
      expect(Tml::Source.normalize("https://travis-ci.org/translationexchange/tml_ruby")).to eq("/translationexchange/tml_ruby")
      expect(Tml::Source.normalize("https://www.google.com/search?q=test&source=lnms")).to eq("/search")
    end
  end
end
