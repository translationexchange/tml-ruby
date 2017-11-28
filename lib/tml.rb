# encoding: UTF-8
#--
# Copyright (c) 2017 Translation Exchange Inc. http://translationexchange.com
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

module Tml
  module Api end
  module Tokens
    module XMessage end
  end
  module Tokenizers end
  module Rules end
  module Decorators end
  module CacheAdapters end
  module Generators end

  def self.default_language
    Tml.config.default_language
  end

  def self.current_language
    Tml.session.current_language
  end

  def self.language(locale)
    Tml.session.application.language(locale)
  end

  def self.translate(label, description = '', tokens = {}, options = {})
    Tml.session.translate(label, description, tokens, options)
  end

  def self.with_options(opts)
    Tml.session.with_options(opts) do
      if block_given?
        yield
      end
    end
  end
end

%w(tml/base.rb tml tml/api tml/rules_engine tml/tokens tml/tokens/x_message tml/tokenizers tml/decorators tml/cache_adapters tml/cache tml/ext).each do |f|
  if f.index('.rb')
    require(File.expand_path(File.join(File.dirname(__FILE__), f)))
    next
  end

  Dir[File.expand_path("#{File.dirname(__FILE__)}/#{f}/*.rb")].sort.each do |file|
    require(file)
  end
end

