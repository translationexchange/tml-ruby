# encoding: UTF-8

require 'spec_helper'

describe Array do
  describe 'extensions' do
    it 'should properly translate elements' do
      expect([1, ['Apple', 'apple'], 'Banana', 'Orange'].tro).to eq([1, ["Apple", "apple"], ["Banana", "Banana"], ["Orange", "Orange"]])

      expect(['Apple', 'Banana', 'Orange', 1].translate_and_join).to eq('Apple, Banana, Orange, 1')

      expect(['Apple', 'Banana', 'Orange'].translate_sentence).to eq('Apple, Banana and Orange')
    end
  end

end
