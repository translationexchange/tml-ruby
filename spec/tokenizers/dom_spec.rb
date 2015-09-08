# encoding: UTF-8

require 'spec_helper'
require 'nokogiri'

describe Tml::Tokenizers::Dom do
  describe "initialize" do
    it "should parse the text correctly" do
      tokenizer = Tml::Tokenizers::Dom.new({}, {
          debug: true,
          debug_format: '{{{{$0}}}}'
      })

      expect(
          tokenizer.translate("<html><body><h1>Mr. Belvedere Fan Club</h1></body></html>")
      ).to eq("<h1>{{{Mr. Belvedere Fan Club}}}</h1>")

      expect(
          tokenizer.translate("Mr. Belvedere Fan Club")
      ).to eq("{{{Mr. Belvedere Fan Club}}}")

      expect(
          tokenizer.translate("<h1>Mr. Belvedere Fan Club</h1>")
      ).to eq("<h1>{{{Mr. Belvedere Fan Club}}}</h1>")

      expect(
          tokenizer.translate("<p><a class='the-link' href='https://github.com/tmpvar/jsdom'>jsdom's Homepage</a></p>")
      ).to eq("<p><a class='the-link' href='https://github.com/tmpvar/jsdom'>{{{jsdom's Homepage}}}</a></p>")

      Dir["#{fixtures_root}/dom/**/*.html"].each do |file|
        original = File.read(file)
        result = File.read(file.gsub(/html$/, 'tml'))
        expect(tokenizer.translate(original)).to eq(result)
      end

    end
  end
end

