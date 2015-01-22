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

class Tml::LanguageCaseRule < Tml::Base
  belongs_to  :language_case
  attributes  :id, :description, :examples, :conditions, :conditions_expression, :operations, :operations_expression

  def conditions_expression
    self.attributes[:conditions_expression] ||= Tml::RulesEngine::Parser.new(self.conditions).parse
  end

  def operations_expression
    self.attributes[:operations_expression] ||= Tml::RulesEngine::Parser.new(self.operations).parse
  end

  def gender_variables(object)
    return {} unless self.conditions.index('@gender')
    return {'@gender' => 'unknown'} unless object
    context = language_case.language.context_by_keyword(:gender)
    return {'@gender' => 'unknown'} unless context
    context.vars(object)
  end

  def evaluate(value, object = nil)
    return false if conditions.nil?

    re = Tml::RulesEngine::Evaluator.new
    re.evaluate(['let', '@value', value])

    gender_variables(object).each do |key, value|
      re.evaluate(['let', key, value])
    end

    re.evaluate(conditions_expression)
  end

  def apply(value)
    value = value.to_s
    return value if operations.nil?

    re = Tml::RulesEngine::Evaluator.new
    re.evaluate(['let', '@value', value])

    re.evaluate(operations_expression)
  end

end