# encoding: UTF-8
#--
# Copyright (c) 2016 Translation Exchange, Inc
#
#  _______                  _       _   _             ______          _
# |__   __|                | |     | | (_)           |  ____|        | |
#    | |_ __ __ _ _ __  ___| | __ _| |_ _  ___  _ __ | |__  __  _____| |__   __ _ _ __   __ _  ___
#    | | '__/ _` | '_ \/ __| |/ _` | __| |/ _ \| '_ \|  __| \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
#    | | | | (_| | | | \__ \ | (_| | |_| | (_) | | | | |____ >  < (__| | | | (_| | | | | (_| |  __/
#    |_|_|  \__,_|_| |_|___/_|\__,_|\__|_|\___/|_| |_|______/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
#                                                                                        __/ |
#                                                                                       |___/
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'digest/md5'

class Tml::Source < Tml::Base
  belongs_to  :application
  attributes  :key, :source, :url, :name, :description
  has_many    :translations, :ignored_keys

  def self.normalize(url)
    return nil if url.nil? or url == ''
    uri = URI.parse(url)
    path = uri.path
    return '/' if uri.path.nil? or uri.path == ''
    return path if path == '/'

    # always must start with /
    path = "/#{path}" if path[0] != '/'
    # should not end with /
    path = path[0..-2] if path[-1] == '/'
    path
  end

  def self.generate_key(source)
    "#{Digest::MD5.hexdigest("#{source}")}~"[0..-2]
  end

  def self.cache_key(locale, source)
    File.join(locale, 'sources', source.split('/'))
  end

  def initialize(attrs = {})
    super
    self.key ||= Tml::Source.generate_key(attrs[:source])
  end

  def ignored_key?(key)
    return false if ignored_keys.nil?
    not ignored_keys.index(key).nil?
  end

  def update_translations(locale, data)
    self.translations ||= {}
    self.translations[locale] = {}
    self.ignored_keys = data['ignored_keys'] || []

    data = data['results'] if data.is_a?(Hash) and data['results']

    data.each do |key, data|
      translations_data = data.is_a?(Hash) ? data['translations'] : data
      self.translations[locale][key] = translations_data.collect do |t|
        Tml::Translation.new(
          locale:   t['locale'] || locale,
          label:    t['label'],
          locked:   t['locked'],
          context:  t['context']
        )
      end
    end
  end

  def fetch_translations(locale)
    self.translations ||= {}
    return self if Tml.session.block_option(:dry)
    return self if self.translations[locale]

    # Tml.logger.debug("Fetching #{source}")

    data = self.application.api_client.get(
      "sources/#{self.key}/translations",
      {:locale => locale, :all => true, :ignored => true},
      {:cache_key => Tml::Source.cache_key(locale, self.source), :raw => true}
    ) || []

    update_translations(locale, data)

    self
  rescue Tml::Exception => ex
    self.translations = {}
    self
  end

  def cached_translations(locale, key)
    self.translations ||= {}
    self.translations[locale] ||= {}
    self.translations[locale][key]
  end

  def reset_cache
    application.languages.each do |lang|
      Tml.cache.delete(Tml::Source.cache_key(lang.locale, self.source))
    end
  end
end