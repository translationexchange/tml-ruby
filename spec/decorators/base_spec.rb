# encoding: UTF-8

require 'spec_helper'

describe Tml::Decorators::Base do
  describe 'creating new decorator' do
    it 'must return a decorator specified in the config file' do
      decor = Tml::Decorators::Base.decorator
      expect(decor.class.name).to eq('Tml::Decorators::Default')

      expect{Tml::Decorators::Base.new.decorate(nil, nil, nil, nil)}.to raise_error(Tml::Exception)
    end
  end
end
