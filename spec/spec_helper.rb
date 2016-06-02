# encoding: UTF-8

require 'rspec'
require 'json'
require 'pp'

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
])
SimpleCov.start

require 'tml'

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end

Tml.configure do |config|
  config.format = :text
end

def fixtures_root
  File.join(File.dirname(__FILE__), 'fixtures')
end

def load_data(file_path)
  File.read("#{fixtures_root}/#{file_path}")
end

def load_json(file_path)
  JSON.parse(load_data(file_path))
end

def load_translation_key_from_hash(app, hash)
  key = Tml::TranslationKey.generate_key(hash['label'], hash['description'])
  hash['translations'].each do |locale, translations|
    app.cache_translations(locale, key, translations)
  end
end

def load_translation_key_from_array(app, arr)
  arr.each do |tkey|
    load_translation_key_from_hash(app, tkey)
  end
end

def load_translation_keys_from_file(app, path)
  load_translation_key_from_array(app, load_json(path))
end

def stub_object(attrs)
  user = double()
  attrs.each do |key, value|
    user.stub(key) { value }
  end
  user
end

def init_application(locales = [], path = 'application.json')
  locales = %w(en ru es) if locales.size == 0
  app = Tml::Application.new(load_json(path))
  locales.each do |locale|
    app.add_language(Tml::Language.new(load_json("languages/#{locale}.json")))
  end
  Tml.session.application = app
  Tml.session.current_language = app.language('en')
  app
end

RSpec.configure do |config|
  config.before do
    ARGV.replace []
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

  def source_root
    fixtures_root
  end
  
  def destination_root
    File.join(File.dirname(__FILE__), 'sandbox')
  end

  alias :silence :capture
end

