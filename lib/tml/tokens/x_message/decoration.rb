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

#######################################################################
#
# Param Token
#
# {0} tagged himself/herself in {1,choice,singular#{1,number} {2,map,photo#photo|video#video}|plural#{1,number} {2,map,photo#photos|video#videos}}.
#
#######################################################################

class Tml::Tokens::XMessage::Decoration < Tml::Tokens::Decoration

  DEFAILT_DECORATION_PLACEHOLDER = '{!yield!}'

  # {:index => "2",
  #  :type => "anchor",
  #  :styles => ...
  # }
  def initialize(label, opts)
    @label = label
    @type = opts[:type]
    @short_name = opts[:index].to_s.gsub(':', '')
    @full_name = "#{opts[:index]}}"
    @default_name = @type
  end

  def token_value(token_object, language)
    token_object
  end

  def token_object(token_values)
    if token_values.is_a?(Array)
      token_values[@short_name.to_i]
    else
      Tml::Utils.hash_value(token_values, @short_name)
    end
  end

  def template(method)
    if method
      if method.is_a?(String)
        if @type == 'anchor'
          return "<a href='#{method}'>#{DEFAILT_DECORATION_PLACEHOLDER}</a>"
        end

        return method
      end

      if method.is_a?(Array) or method.is_a?(Hash)
        return default_decoration(DEFAILT_DECORATION_PLACEHOLDER, method)
      end

      return DEFAILT_DECORATION_PLACEHOLDER
    end

    if Tml.config.default_token_value(@default_name, :decoration)
      return default_decoration(DEFAILT_DECORATION_PLACEHOLDER)
    end

    ''
  end

  def open_tag(method)
    @template = template(method)
    # pp label: label, type: @type, template: @template, method: method
    @template.split(DEFAILT_DECORATION_PLACEHOLDER).first
  end

  def close_tag
    @template.split(DEFAILT_DECORATION_PLACEHOLDER).last
  end

end
