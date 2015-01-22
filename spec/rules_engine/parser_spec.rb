# encoding: UTF-8

require 'spec_helper'

describe Tml::RulesEngine::Parser do
  describe '#parser' do
    it 'parses expressions' do
      expect(Tml::RulesEngine::Parser.new('(= 1 (mod n 10))').tokens).to eq(
          ['(', '=', '1', '(', 'mod', 'n', '10', ')', ')']
      )

      expect(Tml::RulesEngine::Parser.new('(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))').tokens).to eq(
          ['(', '&&', '(', '=', '1', '(', 'mod', '@n', '10', ')', ')', '(', '!=', '11', '(', 'mod', '@n', '100', ')', ')', ')']
      )

      {
          '(= 1 1)' => ['=', 1, 1],
          '(+ 1 1)' => ['+', 1, 1],
          '(= 1 (mod n 10))' => ['=', 1, ['mod', 'n', 10]],
          '(&& 1 1)' => ['&&', 1, 1],
          '(mod @n 10)' => ['mod', '@n', 10],
          '(&& (= 1 (mod @n 10)) (!= 11 (mod @n 100)))' => ['&&', ['=', 1, ['mod', '@n', 10]], ['!=', 11, ['mod', '@n', 100]]],
          "(&& (in '2..4' (mod @n 10)) (not (in '12..14' (mod @n 100))))" => ['&&', ['in', '2..4', ['mod', '@n', 10]], ['not', ['in', '12..14', ['mod', '@n', 100]]]],
          "(|| (= 0 (mod @n 10)) (in '5..9' (mod @n 10)) (in '11..14' (mod @n 100)))" => ['||', ['=', 0, ['mod', '@n', 10]], ['in', '5..9', ['mod', '@n', 10]], ['in', '11..14', ['mod', '@n', 100]]]
      }.each do |source, target|
        expect(Tml::RulesEngine::Parser.new(source).parse).to eq(target)
      end

    end
  end
end
