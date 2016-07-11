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

      dt = Tml::Tokenizers::Data.new('{count:number || one: One, other: Multiple } violations')
      expect(dt.tokens.count).to equal(1)
      expect(dt.tokens.first.name).to eq('count')
      expect(dt.tokens.first.name(:parens => true)).to eq('{count}')
      expect(dt.tokens.first.context_keys).to eq(['number'])
      expect(dt.tokens.first.pipe_separator).to eq('||')
      expect(dt.tokens.first.piped_params.count).to eq(2)
      expect(dt.tokens.first.piped_params[1]).to eq('other: Multiple')

      dt = Tml::Tokenizers::Data.new('{user:gender | male: A man, female: A girl } wishes you luck!')
      expect(dt.tokens.count).to equal(1)
      expect(dt.tokens.first.name).to eq('user')
      expect(dt.tokens.first.name(:parens => true)).to eq('{user}')
      expect(dt.tokens.first.context_keys).to eq(['gender'])
      expect(dt.tokens.first.pipe_separator).to eq('|')
      expect(dt.tokens.first.piped_params.count).to eq(2)
      expect(dt.tokens.first.piped_params[1]).to eq('female: A girl')
    end
  end
end

