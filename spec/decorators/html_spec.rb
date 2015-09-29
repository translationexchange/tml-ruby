# encoding: UTF-8

require 'spec_helper'

describe Tml::Decorators::Html do
  describe 'html decorator' do
    it 'should decorate the label according to the options' do
      decor = Tml::Decorators::Html.new

      app = init_application
      en = app.language('en')
      ru = app.language('ru')
      es = app.language('es')

      translation_key = Tml::TranslationKey.new({
        :label => 'Hello World',
        :application => app,
        :locale => 'en'
      })

      expect(decor.decorate('Hello World', en, en, translation_key, {:skip_decorations => true})).to eq('Hello World')
      Tml.session.current_translator = nil
      expect(decor.decorate('Hello World', en, en, translation_key)).to eq('Hello World')

      Tml.session.current_translator = Tml::Translator.new
      expect(decor.decorate('Hello World', en, en, translation_key)).to eq('Hello World')

      Tml.session.current_translator = Tml::Translator.new
      Tml.session.current_translator.inline = false
      expect(decor.decorate('Hello World', en, en, translation_key)).to eq('Hello World')
      Tml.session.current_translator.inline = true
      expect(decor.decorate('Hello World', en, en, translation_key)).to eq('Hello World')

      expect(decor.decorate('Privet Mir', ru, ru, translation_key)).to eq("<tml:label class='tml_translatable tml_translated' data-translation_key='d541c79af1be6a05b1f16fca8b5730de' data-target_locale='ru'>Privet Mir</tml:label>")
      expect(decor.decorate('Privet Mir', ru, ru, translation_key, {:use_div => true})).to eq("<div class='tml_translatable tml_translated' data-translation_key='d541c79af1be6a05b1f16fca8b5730de' data-target_locale='ru'>Privet Mir</div>")
      expect(decor.decorate('Privet Mir', ru, ru, translation_key, {:use_span => true})).to eq("<span class='tml_translatable tml_translated' data-translation_key='d541c79af1be6a05b1f16fca8b5730de' data-target_locale='ru'>Privet Mir</span>")

      translation_key.id = 5
      expect(decor.decorate('Hello World', en, ru, translation_key)).to eq("<tml:label class='tml_translatable tml_not_translated' data-translation_key='d541c79af1be6a05b1f16fca8b5730de' data-target_locale='ru'>Hello World</tml:label>")
      expect(decor.decorate('Privet Mir', ru, ru, translation_key)).to eq("<tml:label class='tml_translatable tml_translated' data-translation_key='d541c79af1be6a05b1f16fca8b5730de' data-target_locale='ru'>Privet Mir</tml:label>")

      expect(decor.decorate('Hola Mir', es, ru, translation_key)).to eq("<tml:label class='tml_translatable tml_fallback' data-translation_key='d541c79af1be6a05b1f16fca8b5730de' data-target_locale='ru'>Hola Mir</tml:label>")

      expect(decor.decorate('Privet Mir', ru, ru, translation_key, {locked: true})).to eq("<tml:label class='tml_translatable tml_locked' data-translation_key='d541c79af1be6a05b1f16fca8b5730de' data-target_locale='ru'>Privet Mir</tml:label>")

      expect(decor.decorate('Privet Mir', ru, ru, translation_key)).to eq("<tml:label class='tml_translatable tml_translated' data-translation_key='d541c79af1be6a05b1f16fca8b5730de' data-target_locale='ru'>Privet Mir</tml:label>")
    end
  end
end
