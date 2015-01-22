# encoding: UTF-8

require 'spec_helper'

describe Tml::Decorators::Default do
  describe 'default decorator' do
    it 'should return label as is without applying decorations' do
      decor = Tml::Decorators::Default.new
      expect(decor.decorate('Hello World', nil, nil, nil)).to eq('Hello World')
    end
  end
end
