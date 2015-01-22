# encoding: UTF-8
#--
# Copyright (c) 2015 Translation Exchange, Inc
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

class Tml::LanguageContext < Tml::Base
  belongs_to  :language
  attributes  :keyword, :description, :default_key, :token_expression, :variables, :token_mapping
  has_many    :keys, :rules

  def initialize(attrs = {})
    super

    self.attributes[:rules] = {}
    if hash_value(attrs, :rules)
      hash_value(attrs, :rules).each do |key, rule|
        self.attributes[:rules][key] = Tml::LanguageContextRule.new(rule.merge(
         :keyword => key,
         :language_context => self
        ))
      end
    end
  end

  def config
    context_rules = Tml.config.context_rules
    hash_value(context_rules, self.keyword.to_sym) || {}
  end

  def token_expression
    @token_expression ||= begin
      exp = self.attributes[:token_expression]
      exp = Regexp.new(exp[1..-2])
      exp
    end
  end

  def applies_to_token?(token)
    token_expression.match(token) != nil
  end

  def fallback_rule
    @fallback_rule ||= rules.values.detect{|rule| rule.fallback?}
  end

  # prepare variables for evaluation
  def vars(obj)
    vars = {}

    variables.each do |key|
      method = hash_value(config, "variables.#{key}")
      unless method
        vars[key] = obj
        next
      end

      if method.is_a?(String)
        if obj.is_a?(Hash)
          object = hash_value(obj, 'object') || obj
          if object.is_a?(Hash)
            vars[key] = hash_value(object, method, :whole => true)
          else
            vars[key] = object.send(method)
          end
        elsif obj.is_a?(String)
          vars[key] = obj
        else
          vars[key] = obj.send(method)
        end
      elsif method.is_a?(Proc)
        vars[key] = method.call(obj)
      else
        vars[key] = obj
      end

      vars[key] = vars[key].to_s if vars[key].is_a?(Symbol)
    end
    vars
  end

  def find_matching_rule(obj)
    token_vars = vars(obj)
    rules.values.each do |rule|
      next if rule.fallback?
      return rule if rule.evaluate(token_vars)
    end
    fallback_rule
  end

end
