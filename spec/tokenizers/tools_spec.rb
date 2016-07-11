# encoding: UTF-8

require 'spec_helper'

describe Tml::Tokenizers::Tools do

  describe "tools" do
    it 'should correctly add data tokens to parsed short decorations' do
      text = '[bold: Hello {user}!]'
      dt = Tml::Tokenizers::Decoration.new(text)
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello {user}!', ']', '[/tml]'])
      parsed = dt.parse
      expect(parsed).to eq(['tml', ['bold', 'Hello {user}!']])

      # [operator1, operand1, [operator2, operand2, operand3]]

      # ['tml', ['bold', 'Hello {user}!']

      # tml(bold('Hello {user}!'))
      # <tml><bold>Hello {user}!</bold></tml>

      # [{type: 'decoration', name: 'tml', short: true}, [{name: 'bold'}, {label: 'Hello {user}!', tokens: [{type: 'data', name: 'user'}]}]]

      # [bold: Hello {user}!]  =>  [[[ ]]]

      tokenized_data = Tml::Tokenizers::Data.new(text)

      replaced = Tml::Tokenizers::Tools.include_data_tokens(parsed, tokenized_data)
      expect(replaced[1][2]).to eq(['user', 'user'])
      expect(replaced[1].token_type).to eq(:short)
      expect(replaced[1][2].token_type).to eq('data')
      expect(replaced[1][2].token_obj.full_name).to eq('{user}')

      # space after short tag opener disappears
      # expect(replaced[1][1][0]).to eq(' ')
    end

    it 'should correctly add data tokens to parsed long decorations' do
      text = '[bold]Hello {user}![/bold]'
      dt = Tml::Tokenizers::Decoration.new(text)
      expect(dt.fragments).to eq(['[tml]', '[bold]', 'Hello {user}!', '[/bold]', '[/tml]'])
      parsed = dt.parse
      expect(parsed).to eq(['tml', ['bold', 'Hello {user}!']])

      # [operator1, operand1, [operator2, operand2, operand3]]

      # ['tml', ['bold', 'Hello {user}!']

      # tml(bold('Hello {user}!'))
      # <tml><bold>Hello {user}!</bold></tml>

      # [{type: 'decoration', name: 'tml', short: true}, [{name: 'bold'}, {label: 'Hello {user}!', tokens: [{type: 'data', name: 'user'}]}]]

      # [bold: Hello {user}!]  =>  [[[ ]]]

      tokenized_data = Tml::Tokenizers::Data.new(text)

      replaced = Tml::Tokenizers::Tools.include_data_tokens(parsed, tokenized_data)
      expect(replaced[1][2]).to eq(['user', 'user'])
      expect(replaced[1].token_type).to eq(:long)
      expect(replaced[1][2].token_type).to eq('data')
      expect(replaced[1][2].token_obj.full_name).to eq('{user}')

      # space after short tag opener disappears
      # expect(replaced[1][1][0]).to eq(' ')
    end

    it 'should correctly wrap short decoration tokens with custom formatter' do
      text = '[bold]Hello Michael![/bold]'
      dt = Tml::Tokenizers::Decoration.new(text)
      expect(dt.fragments).to eq(['[tml]', '[bold]', 'Hello Michael!', '[/bold]', '[/tml]'])
      parsed = dt.parse
      expect(parsed).to eq(['tml', ['bold', 'Hello Michael!']])

      formatted = Tml::Tokenizers::Tools.format_parsed_key(parsed, {
          :start => lambda { |i| '[[[ ' + i + ' ]]]' },
          :end => lambda { |i| '[[[ ' + i + ' ]]]' }
      })

      expect(formatted).to eq('[[[ [bold] ]]]Hello Michael![[[ [/bold] ]]]')

    end

    it 'should correctly wrap long decoration tokens with custom formatter' do
      text = '[bold: Hello Michael!]'
      dt = Tml::Tokenizers::Decoration.new(text)
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello Michael!', ']', '[/tml]'])
      parsed = dt.parse
      expect(parsed).to eq(['tml', ['bold', 'Hello Michael!']])

      formatted = Tml::Tokenizers::Tools.format_parsed_key(parsed, {
          :start => lambda { |i| '[[[ ' + i + ' ]]]' },
          :end => lambda { |i| '[[[ ' + i + ' ]]]' }
      })

      expect(formatted).to eq('[[[ [bold: ]]]Hello Michael![[[ ] ]]]')

    end
  end

end

