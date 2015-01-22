# encoding: UTF-8

require 'spec_helper'

describe Tml::RulesEngine::Evaluator do
  describe '#evaluator' do
    it 'evaluates standard expressions' do
      e = Tml::RulesEngine::Evaluator.new
      e.evaluate(['label', 'greeting', 'hello world'])
      expect(e.vars).to eq({'greeting'=>'hello world'})

      expect(e.evaluate(['quote', [1,2,3]])).to eq([1,2,3])
      expect(e.evaluate(['quote', ['a','b','c']])).to eq(['a','b','c'])

      expect(e.evaluate(['car', ['+', 1, 2]])).to eq(1)
      expect(e.evaluate(['cdr', ['+', 1, 2]])).to eq([1, 2])
      expect(e.evaluate(['cons', 1, ['quote', [2, 3]]])).to eq([1, 2, 3])

      expect(e.evaluate(['eq', 1, 1])).to be_truthy

      expect(e.evaluate(['atom', :a])).to be_truthy
      expect(e.evaluate(['atom', 'hello'])).to be_truthy
      expect(e.evaluate(['atom', 1])).to be_truthy
      expect(e.evaluate(['atom', 1.4])).to be_truthy
      expect(e.evaluate(['atom', ['eq', 1, 1]])).to be_falsey

      expect(e.evaluate(['cond', ['eq', 1, 1], 1, 0])).to eq(1)
      expect(e.evaluate(['cond', ['eq', 1, 2], 1, 0])).to eq(0)
    end

    it 'evaluates rules' do
      e = Tml::RulesEngine::Evaluator.new
      expect(e.evaluate(['=', '1', '1'])).to be_truthy
      expect(e.evaluate(['=', '1', '2'])).to be_falsey

      expect(e.evaluate(['!=', '2', '1'])).to be_truthy
      expect(e.evaluate(['!=', '2', '2'])).to be_falsey

      expect(e.evaluate(['>', '2', '1'])).to be_truthy
      expect(e.evaluate(['>', '1', '2'])).to be_falsey

      expect(e.evaluate(['<', '2', '3'])).to be_truthy
      expect(e.evaluate(['<', '3', '2'])).to be_falsey

      expect(e.evaluate(['+', 1, 2])).to eq(3)
      expect(e.evaluate(['+', -1, 2])).to eq(1)

      expect(e.evaluate(['-', 2, 1])).to eq(1)
      expect(e.evaluate(['*', 2, 10])).to eq(20)
      expect(e.evaluate(['/', 20, 10])).to eq(2)

      expect(e.evaluate(['!', ['=', '1', '2']])).to be_truthy

      expect(e.evaluate(['&&', ['=', '1', '1'], ['=', 10, ['/', 20, 2]]])).to be_truthy
      expect(e.evaluate(['||', ['=', '2', '1'], ['=', 10, ['/', 20, 2]]])).to be_truthy

      expect(e.evaluate(['if', ['=', 1, 2], 1, 0])).to eq(0)

      e.evaluate(['let', '@n', 1])
      expect(e.vars).to eq({'@n'=>1})
      expect(e.evaluate(['=', 1, '@n'])).to be_truthy

      e.evaluate(['let', '@n', 11])
      expect(e.vars).to eq({'@n'=>11})
      expect(e.evaluate(['=', 11, '@n'])).to be_truthy

      expect(e.evaluate(['and', ['=', '1', '1'], ['=', 10, ['/', 20, 2]]])).to be_truthy
      expect(e.evaluate(['or', ['=', '2', '1'], ['=', 10, ['/', 20, 2]]])).to be_truthy

      expect(e.evaluate(['mod', 23, 10])).to eq(3)
      expect(e.evaluate(['mod', 2.3, 10])).to eq(2.3)

      expect(e.evaluate(['match', '/hello/', 'hello world'])).to be_truthy
      expect(e.evaluate(['match', 'hello', 'hello world'])).to be_truthy
      expect(e.evaluate(['match', '/^h/', 'hello world'])).to be_truthy
      expect(e.evaluate(['match', '/^e/', 'hello world'])).to be_falsey
      expect(e.evaluate(['match', '/^h.*d$/', 'hello world'])).to be_truthy

      expect(e.evaluate(['in', '1,2', '1'])).to be_truthy
      expect(e.evaluate(['in', '1,2', 1])).to be_truthy
      expect(e.evaluate(['in', 'a,b,c', 'a'])).to be_truthy
      expect(e.evaluate(['in', 'a..c, d..z', 'h'])).to be_truthy

      expect(e.evaluate(['in', '1..5, 10..22', 21])).to be_truthy
      expect(e.evaluate(['in', '1..5, 10..22', 22])).to be_truthy
      expect(e.evaluate(['in', '1..5, 10..22', 1])).to be_truthy
      expect(e.evaluate(['in', '1..5, 10..22', 23])).to be_falsey
      expect(e.evaluate(['in', '1..5, 10..22', '9'])).to be_falsey

      expect(e.evaluate(['within', '1..3', 2.3])).to be_truthy
      expect(e.evaluate(['within', '1..3', 3.3])).to be_falsey

      expect(e.evaluate(['replace', '/^hello/', 'hi', 'hello world'])).to eq('hi world')
      expect(e.evaluate(['replace', 'world', 'hi', 'hello world'])).to eq('hello hi')
      expect(e.evaluate(['replace', 'o', 'a', 'hello world'])).to eq('hella warld')
      expect(e.evaluate(['replace', '/world$/', 'moon', 'hello moon'])).to eq('hello moon')

      expect(e.evaluate(['append', 'world', 'hello '])).to eq('hello world')
      expect(e.evaluate(['prepend', 'hello ', 'world'])).to eq('hello world')

      expect(e.evaluate(['true'])).to be_truthy
      expect(e.evaluate(['false'])).to be_falsey

      expect(e.evaluate(['date', '2011-01-01'])).to eq(Date.new(2011, 1, 1))
      expect(e.evaluate(['today'])).to eq(Date.today)

      expect(e.evaluate(['time', '2011-01-01 10:9:8'])).to eq(Time.new(2011, 1, 1, 10, 9, 8))

      expect(e.evaluate(['>', ['date', '3014-01-01'], ['today']])).to be_truthy
    end

    it 'evaluates expressions' do
      e = Tml::RulesEngine::Evaluator.new

      e.evaluate(['let', '@n', 1])
      expect(e.evaluate(['&&', ['=', 1, ['mod', '@n', 10]], ['!=', 11, ['mod', '@n', 100]]])).to be_truthy
      expect(e.evaluate(['&&', ['in', '2..4', ['mod', '@n', 10]], ['not', ['in', '12..14', ['mod', '@n', 100]]]])).to be_falsey
      expect(e.evaluate(['||', ['=', 0, ['mod', '@n', 10]], ['in', '5..9', ['mod', '@n', 10]], ['in', '11..14', ['mod', '@n', 100]]])).to be_falsey

      e.evaluate(['let', '@n', 21])
      expect(e.evaluate(['&&', ['=', 1, ['mod', '@n', 10]], ['!=', 11, ['mod', '@n', 100]]])).to be_truthy
      expect(e.evaluate(['&&', ['in', '2..4', ['mod', '@n', 10]], ['not', ['in', '12..14', ['mod', '@n', 100]]]])).to be_falsey
      expect(e.evaluate(['||', ['=', 0, ['mod', '@n', 10]], ['in', '5..9', ['mod', '@n', 10]], ['in', '11..14', ['mod', '@n', 100]]])).to be_falsey

      e.evaluate(['let', '@n', 11])
      expect(e.evaluate(['&&', ['=', 1, ['mod', '@n', 10]], ['!=', 11, ['mod', '@n', 100]]])).to be_falsey
      expect(e.evaluate(['&&', ['in', '2..4', ['mod', '@n', 10]], ['not', ['in', '12..14', ['mod', '@n', 100]]]])).to be_falsey
      expect(e.evaluate(['||', ['=', 0, ['mod', '@n', 10]], ['in', '5..9', ['mod', '@n', 10]], ['in', '11..14', ['mod', '@n', 100]]])).to be_truthy

      rules = {
          'one' => ['&&', ['=', 1, ['mod', '@n', 10]], ['!=', 11, ['mod', '@n', 100]]],
          'few' => ['&&', ['in', '2..4', ['mod', '@n', 10]], ['not', ['in', '12..14', ['mod', '@n', 100]]]],
          'many' => ['||', ['=', 0, ['mod', '@n', 10]], ['in', '5..9', ['mod', '@n', 10]], ['in', '11..14', ['mod', '@n', 100]]]
      }

      {
          'one' => [1, 21, 31, 41, 51, 61],
          'few' => [2,3,4, 22,23,24, 32,33,34],
          'many' => [0, 5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20, 25,26,27,28,29,30, 35,36,37,38,39,40]
      }.each do |key, values|
        values.each do |value|
          e.evaluate(['let', '@n', value])
          expect(e.evaluate(rules[key])).to be_truthy
        end
      end

    end

  end
end
