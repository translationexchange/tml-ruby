# encoding: UTF-8

require 'spec_helper'

describe Hash do
  it 'must provide correct attributes' do
    Tml.session.with_block_options(:dry => true) do
      h1 = {'a' => 100, 'b' => 200, 'c' => {'c1' => 12, 'c2' => 14}}
      h2 = {'b' => 254, 'c' => {'c1' => 16, 'c3' => 94}}
      expect(h1.rmerge(h2)).to eq({'a' => 100, 'b' => 254, 'c' => {'c1' => 16, 'c2' => 14, 'c3' => 94}})
      expect(h1.rmerge!(h2)).to eq({'a' => 100, 'b' => 254, 'c' => {'c1' => 16, 'c2' => 14, 'c3' => 94}})
    end
  end
end
