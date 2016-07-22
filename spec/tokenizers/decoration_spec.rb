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

      dt = Tml::Tokenizers::Decoration.new('[bold: Hello World')
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello World', '[/tml]'])
      expect(dt.parse).to eq(['tml', ['bold', 'Hello World']])

      dt = Tml::Tokenizers::Decoration.new('[bold: Hello [strong: World]]')
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello ', '[strong:', ' World', ']', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', ['bold', 'Hello ', ['strong', 'World']]])

      dt = Tml::Tokenizers::Decoration.new('[bold: Hello [strong: World]')
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello ', '[strong:', ' World', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', ['bold', 'Hello ', ['strong', 'World']]])

      dt = Tml::Tokenizers::Decoration.new('[bold1: Hello [strong22: World]]')
      expect(dt.fragments).to eq(['[tml]', '[bold1:', ' Hello ', '[strong22:', ' World', ']', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', ['bold1', 'Hello ', ['strong22', 'World']]])

      dt = Tml::Tokenizers::Decoration.new('[bold: Hello, [strong: how] [weak: are] you?]')
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello, ', '[strong:', ' how', ']', ' ', '[weak:', ' are', ']', ' you?', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', ['bold', 'Hello, ', ['strong', 'how'], ' ', ['weak', 'are'], ' you?']])

      dt = Tml::Tokenizers::Decoration.new('[bold: Hello, [strong: how [weak: are] you?]')
      expect(dt.fragments).to eq(['[tml]', '[bold:', ' Hello, ', '[strong:', ' how ', '[weak:', ' are', ']', ' you?', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', ['bold', 'Hello, ', ['strong', 'how ', ['weak', 'are'], ' you?']]])

      dt = Tml::Tokenizers::Decoration.new('[link: you have [italic: [bold: {count}] messages] [light: in your mailbox]]')
      expect(dt.fragments).to eq(['[tml]', '[link:', ' you have ', '[italic:', ' ', '[bold:', ' {count}', ']', ' messages', ']', ' ', '[light:', ' in your mailbox', ']', ']', '[/tml]'])
      expect(dt.parse).to eq(['tml', ['link', 'you have ', ['italic', '', ['bold', '{count}'], ' messages'], ' ', ['light', 'in your mailbox']]])

      dt = Tml::Tokenizers::Decoration.new('[link] you have [italic: [bold: {count}] messages] [light: in your mailbox] [/link]')
      expect(dt.fragments).to eq(['[tml]', '[link]', ' you have ', '[italic:', ' ', '[bold:', ' {count}', ']', ' messages', ']', ' ', '[light:', ' in your mailbox', ']', ' ', '[/link]', '[/tml]'])
      expect(dt.parse).to eq( ['tml', ['link', ' you have ', ['italic', '', ['bold', '{count}'], ' messages'], ' ', ['light', 'in your mailbox'], ' ']])
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
      expect(dt.substitute).to eq("<a href='http://mail.google.com' class='' style='' title=''>you have 5 messages</a>")

      dt = Tml::Tokenizers::Decoration.new("[link1: you have 5 messages]", "link1" => {href: "http://mail.google.com"})
      expect(dt.substitute).to eq("<a href='http://mail.google.com' class='' style='' title=''>you have 5 messages</a>")

      dt = Tml::Tokenizers::Decoration.new("[link1: you have 5 messages]", link1: {href: "http://mail.google.com"})
      expect(dt.substitute).to eq("<a href='http://mail.google.com' class='' style='' title=''>you have 5 messages</a>")
    end
  end

  describe 'default decorations' do
    it 'should be cleaned' do
      html = '<a href="/newest/test" class="{$class}" style="{$style}" title="{$title}"></a>'
      html = html.gsub(/\{\$[^}]*\}/, '')
      expect(html).to eq('<a href="/newest/test" class="" style="" title=""></a>')
    end
  end

end

