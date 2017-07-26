# encoding: UTF-8

require 'spec_helper'

describe Tml::Tokens::Map do
  before do
    @app = init_application
    @english = @app.language('en')
    @tkey = Tml::TranslationKey.new({
                                        :label => 'Hello {user @ friend, enemy}',
                                        :application => @app,
                                        :locale => 'en'
                                    })
    @token = @tkey.data_tokens.first
  end

  describe 'initialize' do
    it 'should parse data token' do
      expect(@token.class.name).to eq('Tml::Tokens::Map')
      expect(@token.context_keys).to eq([])
    end
  end

  describe 'substitute' do
    it 'should perform complete substitution' do
      expect(@token.substitute(@tkey.label, {user: 0}, @english)).to eq('Hello friend')
      expect(@token.substitute(@tkey.label, {user: 1}, @english)).to eq('Hello enemy')

      @tkey = Tml::TranslationKey.new({
                                          :label => 'Hello {user @ friend: friend, enemy: enemy}',
                                          :application => @app,
                                          :locale => 'en'
                                      })
      @token = @tkey.data_tokens.first

      expect(@token.substitute(@tkey.label, {user: 'friend'}, @english)).to eq('Hello friend')
      expect(@token.substitute(@tkey.label, {user: 'enemy'}, @english)).to eq('Hello enemy')
    end
  end

end
