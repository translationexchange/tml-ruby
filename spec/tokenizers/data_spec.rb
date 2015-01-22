# encoding: UTF-8

require 'spec_helper'

describe Tml::Tokenizers::Data do
  before do

  end

  describe 'initialize' do
    it 'should parse the text correctly' do
      dt = Tml::Tokenizers::Data.new('Hello World')
      expect(dt.tokens).to be_empty

      dt = Tml::Tokenizers::Data.new('Hello {world}')
      expect(dt.tokens.count).to equal(1)
      expect(dt.tokens.first.name).to eq('world')
      expect(dt.tokens.first.name(:parens => true)).to eq('{world}')

      dt = Tml::Tokenizers::Data.new('Dear {user:gender}')
      expect(dt.tokens.count).to equal(1)
      expect(dt.tokens.first.name).to eq('user')
      expect(dt.tokens.first.name(:parens => true)).to eq('{user}')
      expect(dt.tokens.first.context_keys).to eq(['gender'])
      expect(dt.tokens.first.name(:parens => true, :context_keys => true)).to eq('{user:gender}')
    end
  end
end

