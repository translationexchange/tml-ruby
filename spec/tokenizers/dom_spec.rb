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

      expect(
          tokenizer.translate("<div>Hello <strong>World</strong></div>")
      ).to eq("<div>{{{Hello [strong: World]}}}</div>")

      expect(
          tokenizer.translate('<p><strong>Apollo 11</strong> was the spaceflight that landed the first humans, Americans <a href="http://en.wikipedia.org/wiki/Neil_Armstrong" title="Neil Armstrong">Neil Armstrong</a> and <a href="http://en.wikipedia.org/wiki/Buzz_Aldrin" title="Buzz Aldrin">Buzz Aldrin</a>, on the Moon on July 20, 1969, at 20:18 UTC. Armstrong became the first to step onto the lunar surface 6 hours later on July 21 at 02:56 UTC.</p>')
      ).to eq("<p>{{{[strong: Apollo 11] was the spaceflight that landed the first humans, Americans [link: Neil Armstrong] and [link1: Buzz Aldrin], on the Moon on July 20, 1969, at 20:18 UTC. Armstrong became the first to step onto the lunar surface 6 hours later on July 21 at 02:56 UTC.}}}</p>")

      original = <<-eos
        <table align="right" border="1" bordercolor="#ccc" cellpadding="5" cellspacing="0" style="border-collapse:collapse; margin:10px 0 10px 15px">
          <caption><strong>Mission crew</strong></caption>
          <thead>
            <tr>
              <th scope="col">Position</th>
              <th scope="col">Astronaut</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Commander</td>
              <td>Neil A. Armstrong</td>
            </tr>
            <tr>
              <td>Command Module Pilot</td>
              <td>Michael Collins</td>
            </tr>
            <tr>
              <td>Lunar Module Pilot</td>
              <td>Edwin &quot;Buzz&quot; E. Aldrin, Jr.</td>
            </tr>
          </tbody>
        </table>
      eos

      result = <<-eos
        <table align='right' border='1' bordercolor='#ccc' cellpadding='5' cellspacing='0' style='border-collapse:collapse; margin:10px 0 10px 15px'>
          <caption><strong>{{{Mission crew}}}</strong></caption>
          <thead>
            <tr>
              <th scope='col'>{{{Position}}}</th>
              <th scope='col'>{{{Astronaut}}}</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>{{{Commander}}}</td>
              <td>{{{Neil A. Armstrong}}}</td>
            </tr>
            <tr>
              <td>{{{Command Module Pilot}}}</td>
              <td>{{{Michael Collins}}}</td>
            </tr>
            <tr>
              <td>{{{Lunar Module Pilot}}}</td>
              <td>{{{Edwin "Buzz" E. Aldrin, Jr.}}}</td>
            </tr>
          </tbody>
        </table>
      eos

      expect(
          tokenizer.translate(original)
      ).to eq(result)

    end
  end
end

