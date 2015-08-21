# encoding: UTF-8

require 'spec_helper'

describe Tml::Cache do
  describe "#initialize" do
    it "features" do
      expect(Tml.cache.strip_extensions({'a' => '123', 'extensions' => 'abc'})).to eq({'a' => '123'})
      expect(Tml.cache.strip_extensions({'a' => '123', 'extensions' => 'abc'}.to_json)).to eq({'a' => '123'}.to_json)

      Tml.cache.info('Test')
      Tml.cache.warn('Test')
    end
  end
end
