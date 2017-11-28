# encoding: UTF-8
#--
# Copyright (c) 2017 Translation Exchange, Inc
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

####################################################################### 
# 
# Map Token Forms
#
# tr("{user} likes this {animal @ dog: dog, cat: cat, bird: bird}", user: "Michael", animal: "dog")
# tr("{user} likes this {animal @ dog, cat, bird}", user: "Michael", animal: 0)
#
####################################################################### 

class Tml::Tokens::Map < Tml::Tokens::Data

  attr_reader :params

  def self.expression
    /(%?\{{1,2}\s*[\w]+\s*@\s*[^\{\}\|]+\}{1,2})/
  end

  def parse_elements
    name_without_parens = @full_name.gsub(/^%/, '')[1..-2]
    @context_keys = []
    @case_keys = []
    @short_name, @params = name_without_parens.split('@')
    @short_name.strip!
    @params = @params.split(',').collect{|param| param.strip}
    if @params.first.index(':')
      hash = {}
      @params.each do |param|
        key, value = param.split(':')
        hash[key.to_s.strip] = value.to_s.strip
      end
      @params = hash
    end
  end

  def substitute(label, context, language, options = {})
    object = self.class.token_object(context, key)

    if object.nil?
      return error("Missing value for a token \"#{key}\" in \"#{label}\"", false)
    end

    if params.empty?
      return error("Params may not be empty for token \"#{key}\" in \"#{label}\"", false)
    end

    object_value = params[object]

    label.gsub(full_name, decorate(object_value, options))
  end

end
