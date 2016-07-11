# encoding: UTF-8

require 'spec_helper'

describe Tml::Tokenizers::Decoration do

  describe "parse" do
    it 'should correctly parse tokens' do
      dt = Tml::Tokenizers::Decoration.new('Hello World')
      expect(dt.fragments).to eq(['[tml]', 'Hello World', '[/tml]'])
      expect(dt.parse).to eq(['tml', 'Hello World'])

      dt = Tml::Tokenizers::Decoration.new('[bold: Hello World]')
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello World', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', ['bold', 'Hello World']])

      dt = Tml::Tokenizers::Decoration.new('<bold>Hello World</bold>')
      expect(dt.fragments).to eq(["[tml]", "<bold>", "Hello World", "</bold>", "[/tml]"])
      expect(dt.parse).to eq(['tml', ['bold', 'Hello World']])

      dt = Tml::Tokenizers::Decoration.new('<bold>Hello <i>World</i></bold>')
      expect(dt.fragments).to eq(["[tml]", "<bold>", "Hello ", "<i>", "World", "</i>", "</bold>", "[/tml]"])
      expect(dt.parse).to eq(["tml", ["bold", "Hello ", ["i", "World"]]])

      dt = Tml::Tokenizers::Decoration.new('[bold: Hello [strong: World]]')
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello ', '[strong:', ' World', ']', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', ['bold', 'Hello ', ['strong', 'World']]])

      dt = Tml::Tokenizers::Decoration.new('[bold1: Hello [strong22: World]]')
      expect(dt.fragments).to eq(['[tml]', '[bold1:', ' Hello ', '[strong22:', ' World', ']', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', ['bold1', 'Hello ', ['strong22', 'World']]])

      dt = Tml::Tokenizers::Decoration.new('[bold: Hello, [strong: how] [weak: are] you?]')
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello, ', '[strong:', ' how', ']', ' ', '[weak:', ' are', ']', ' you?', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', ['bold', 'Hello, ', ['strong', 'how'], ' ', ['weak', 'are'], ' you?']])

      dt = Tml::Tokenizers::Decoration.new('[link: you have [italic: [bold: {count}] messages] [light: in your mailbox]]')
      expect(dt.fragments).to eq(['[tml]', '[link:', ' you have ', '[italic:', ' ', '[bold:', ' {count}', ']', ' messages', ']', ' ', '[light:', ' in your mailbox', ']', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', ['link', 'you have ', ['italic', '', ['bold', '{count}'], ' messages'], ' ', ['light', 'in your mailbox']]])

      dt = Tml::Tokenizers::Decoration.new('[link] you have [italic: [bold: {count}] messages] [light: in your mailbox] [/link]')
      expect(dt.fragments).to eq(['[tml]', '[link]', ' you have ', '[italic:', ' ', '[bold:', ' {count}', ']', ' messages', ']', ' ', '[light:', ' in your mailbox', ']', ' ', '[/link]', '[/tml]'])
      expect(dt.parse).to eq( ['tml', ['link', ' you have ', ['italic', '', ['bold', '{count}'], ' messages'], ' ', ['light', 'in your mailbox'], ' ']])
    end
  end

  describe "bad tags" do
    it 'should correctly handle unclosed long tags' do
      dt = Tml::Tokenizers::Decoration.new('[bold]Hello W[o]rld[/bold]')
      # expect(dt.fragments).to eq(['[tml]', 'Hello World', '[/tml]'])
      parsed = dt.parse
      parsed.shift
      expect(parsed).to eq([['bold', 'Hello W', '[o]', 'rld']])
    end
    it 'should correctly handle unclosed short tags' do
      dt = Tml::Tokenizers::Decoration.new('[bold: Hello World')
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello World', '[/tml]'])
      expect(dt.parse).to eq(['tml', '[bold:', 'Hello World'])
    end
    it 'should correctly nest short tags within unclosed short tags' do
      dt = Tml::Tokenizers::Decoration.new('[bold: Hello [strong: World]')
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello ', '[strong:', ' World', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', '[bold:', 'Hello ', ['strong', 'World']])
    end
    it 'should correctly nest multiple short tags within unclosed short tags' do
      dt = Tml::Tokenizers::Decoration.new('[bold: Hello, [strong: how [weak: are] you?]')
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello, ', '[strong:', ' how ', '[weak:', ' are', ']', ' you?', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', '[bold:', 'Hello, ', ['strong', 'how ', ['weak', 'are'], ' you?']])
    end
    it 'should correctly handle unclosed html tags' do
      dt = Tml::Tokenizers::Decoration.new('[bold]Hello W<o>rld[/bold]')
      parsed = dt.parse
      parsed.shift
      expect(parsed).to eq([['bold', 'Hello W', '<o>', 'rld']])
    end


    ## THE FOLLOWING TESTS ARE WRONG! CLOSING TAG MISSING OPENING [ BRACKET
    it 'should correctly unnest multiple levels of unclosed tags' do
      dt = Tml::Tokenizers::Decoration.new('[bold]Hel[lo: W<o>rld[/bold')
      parsed = dt.parse
      parsed.shift
      expect(parsed).to eq(['[bold]', 'Hel', '[lo:', 'W', '<o>', 'rld', '/bold'])
    end

    it 'should correctly handle unclosed long tags' do
      dt = Tml::Tokenizers::Decoration.new('[span]Hello W[bold: o]rld[/span')
      # expect(dt.fragments).to eq(['[tml]', 'Hello World', '[/tml]'])
      parsed = dt.parse
      parsed.shift
      expect(parsed).to eq(['[span]', 'Hello W', ['bold', 'o'], 'rld', '/span'])
    end


  end

  describe 'substitute' do
    it 'should correctly substitute tokens' do
      dt = Tml::Tokenizers::Decoration.new('[bold: Hello World]')
      expect(dt.substitute).to eq('<strong>Hello World</strong>')

      dt = Tml::Tokenizers::Decoration.new('[bold]Hello World[/bold]')
      expect(dt.substitute).to eq('<strong>Hello World</strong>')

      dt = Tml::Tokenizers::Decoration.new('[bold] Hello World [/bold]')
      expect(dt.substitute).to eq('<strong> Hello World </strong>')

      dt = Tml::Tokenizers::Decoration.new('[p: Hello World]', :p => '<p>{$0}</p>')
      expect(dt.substitute).to eq('<p>Hello World</p>')

      dt = Tml::Tokenizers::Decoration.new('[p: Hello World]', :p => lambda{|text| "<p>#{text}</p>"})
      expect(dt.substitute).to eq('<p>Hello World</p>')

      dt = Tml::Tokenizers::Decoration.new('[p]Hello World[/p]', :p => lambda{|text| "<p>#{text}</p>"})
      expect(dt.substitute).to eq('<p>Hello World</p>')

      dt = Tml::Tokenizers::Decoration.new("[link: you have 5 messages]", "link" => '<a href="http://mail.google.com">{$0}</a>')
      expect(dt.substitute).to eq("<a href=\"http://mail.google.com\">you have 5 messages</a>")

      dt = Tml::Tokenizers::Decoration.new("[link: you have {count} messages]", "link" => '<a href="http://mail.google.com">{$0}</a>')
      expect(dt.substitute).to eq("<a href=\"http://mail.google.com\">you have {count} messages</a>")

      dt = Tml::Tokenizers::Decoration.new("[link: you have 5 messages]", "link" => {href: "http://mail.google.com"})
      expect(dt.substitute).to eq("<a href='http://mail.google.com'>you have 5 messages</a>")

      dt = Tml::Tokenizers::Decoration.new("[link1: you have 5 messages]", "link1" => {href: "http://mail.google.com"})
      expect(dt.substitute).to eq("<a href='http://mail.google.com'>you have 5 messages</a>")

      dt = Tml::Tokenizers::Decoration.new("[link1: you have 5 messages]", link1: {href: "http://mail.google.com"})
      expect(dt.substitute).to eq("<a href='http://mail.google.com'>you have 5 messages</a>")
    end
  end

end

