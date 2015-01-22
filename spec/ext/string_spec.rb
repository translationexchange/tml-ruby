# encoding: UTF-8

require 'spec_helper'

describe String do
  it 'must provide correct attributes' do
    s = ''.tml_translated
    expect(s.tml_translated?).to be_truthy
  end
end
