# encoding: UTF-8

require 'spec_helper'

describe Fixnum do
  describe 'extensions' do
    it 'should properly translate elements' do
      Tml.session.with_block_options(:dry => true) do
        expect(1.with_leading_zero).to eq('01')
        expect(1.tr).to eq('1')
        expect(1.trl).to eq('1')
      end
    end
  end

end
