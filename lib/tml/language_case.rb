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

class Tml::LanguageCase < Tml::Base
  belongs_to  :language
  attributes  :id, :keyword, :latin_name, :native_name, :description, :application
  has_many    :rules

  TR8N_HTML_TAGS_REGEX = /<\/?[^>]*>/

  def initialize(attrs = {})
    super
    self.attributes[:rules] = []
    if hash_value(attrs, :rules)
      self.attributes[:rules] = hash_value(attrs, :rules).collect{ |rule| Tml::LanguageCaseRule.new(rule.merge(:language_case => self)) }
    end
  end

  def find_matching_rule(value, object = nil)
    rules.each do |rule|
      return rule if rule.evaluate(value, object)
    end
    nil
  end

  #######################################################################################################
  ##  Evaluation Methods
  #######################################################################################################

  def apply(value, object = nil, options = {})
    value = value.to_s

    decorator = Tml::Decorators::Base.decorator

    options = options.merge(:skip_decorations => true) if value.index('not_translated')

    html_tokens = value.scan(TR8N_HTML_TAGS_REGEX).uniq
    sanitized_value = value.gsub(TR8N_HTML_TAGS_REGEX, '')

    if application.to_s == 'phrase'
      words = [sanitized_value]
    else
      words = sanitized_value.split(/[\s\/\\]/).uniq
    end

    # replace html tokens with temporary placeholders {$h1}
    html_tokens.each_with_index do |html_token, index|
      value = value.gsub(html_token, "{$h#{index}}")
    end

    # replace words with temporary placeholders {$w1}
    words.each_with_index do |word, index|
      value = value.gsub(word, "{$w#{index}}")
    end

    transformed_words = []
    words.each do |word|
      case_rule = find_matching_rule(word, object)
      case_value = case_rule ? case_rule.apply(word) : word
      transformed_words << decorator.decorate_language_case(self, case_rule, word, case_value, options)
    end

    # replace back the temporary placeholders with the html tokens
    transformed_words.each_with_index do |word, index|
      value = value.gsub("{$w#{index}}", word)
    end

    # replace back the temporary placeholders with the html tokens
    html_tokens.each_with_index do |html_token, index|
      value = value.gsub("{$h#{index}}", html_token)
    end

    value
  end

end
