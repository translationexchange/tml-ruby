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

module Tml
  module Tokens
    class Decoration

      RESERVED_TOKEN = 'tml'
      TOKEN_PLACEHOLDER = '{$0}'

      attr_reader :label, :full_name, :short_name, :default_name

      def initialize(label, token)
        @label = label
        @full_name = token.to_s
        @short_name = @full_name

        # removing the numbers at the end - default tokens don't need them
        @default_name = @short_name.gsub(/(\d)*$/, '')
      end

      def to_s
        full_name
      end

      def default_decoration(token_content, decoration_token_values = nil)
        default_decoration = Tml.config.default_token_value(default_name, :decoration)

        unless default_decoration
          return "<#{short_name}>#{token_content}</#{short_name}>"
        end

        # {$0} always represents the actual content
        default_decoration = default_decoration.gsub(TOKEN_PLACEHOLDER, token_content.to_s)

        # substitute the token values with hash elements
        if decoration_token_values.is_a?(Hash)
          decoration_token_values.each do |key, value|
            default_decoration = default_decoration.gsub("{$#{key}}", value.to_s)
          end
        elsif decoration_token_values.is_a?(Array)
          decoration_token_values.each_with_index do |value, index|
            default_decoration = default_decoration.gsub("{$#{index + 1}}", value.to_s)
          end
        end

        # remove unused attributes
        default_decoration.gsub(/\{\$[^}]*\}/, '')
      end

      def allowed?(allowed_tokens)
        return true if allowed_tokens.nil?
        allowed_tokens.include?(short_name)
      end

      def apply(token_values, token_content, allowed_tokens = nil)
        return token_content if short_name == RESERVED_TOKEN
        return token_content unless allowed?(allowed_tokens)

        method = Tml::Utils.hash_value(token_values, short_name)

        if method
          if method.is_a?(String)
            return method.to_s.gsub(TOKEN_PLACEHOLDER, token_content)
          end

          if method.is_a?(Proc)
            return method.call(token_content)
          end

          if method.is_a?(Array) || method.is_a?(Hash)
            return default_decoration(token_content, method)
          end

          return token_content
        end

        default_decoration(token_content)
      end

    end
  end
end
