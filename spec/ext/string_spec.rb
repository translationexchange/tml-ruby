# encoding: UTF-8

require 'spec_helper'

describe String do
  it 'must provide correct attributes' do
    Tml.session.with_block_options(:dry => true) do
      s = ''.tml_translated
      expect(s.tml_translated?).to be_truthy
    end
  end
end
