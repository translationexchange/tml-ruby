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

#######################################################################
#
# Decoration Token Forms:
#
# [link: click here]
# or
# [link] click here [/link]
#
# Decoration Tokens Allow Nesting:
#
# [link: {count} {_messages}]
# [link: {count||message}]
# [link: {count||person, people}]
# [link: {user.name}]
# [link] {user.name} [/link]
# <link> {user.name} </link>
#
#######################################################################

module Tml
  module Tokenizers
    class Decoration

      attr_reader :tokens, :fragments, :context, :text, :opts

      RESERVED_TOKEN       = 'tml'

      RE_SHORT_TOKEN_START = '\[[\w]*:'
      RE_SHORT_TOKEN_END   = '\]'
      RE_LONG_TOKEN_START  = '\[[\w]*\]'                       # [link]
      RE_LONG_TOKEN_END    = '\[\/[\w]*\]'                     # [/link]
      RE_HTML_TOKEN_START  = '<[^\>]*>'                        # <link>
      RE_HTML_TOKEN_END    = '<\/[^\>]*>'                      # </link>
      RE_TEXT              = '[^\[\]<>]+'                        # '[\w\s!.:{}\(\)\|,?]*'

      def self.required?(label)
        label.index('[') or label.index('<')
      end

      def initialize(text, context = {}, opts = {})
        @text = "[#{RESERVED_TOKEN}]#{text}[/#{RESERVED_TOKEN}]"
        @context = context
        @opts = opts
        tokenize
      end

      def tokenize
        re = [RE_SHORT_TOKEN_START,
              RE_SHORT_TOKEN_END,
              RE_LONG_TOKEN_START,
              RE_LONG_TOKEN_END,
              RE_HTML_TOKEN_START,
              RE_HTML_TOKEN_END,
              RE_TEXT].join('|')
        @fragments = text.scan(/#{re}/)
        @tokens = []
      end

      def parse
        return @text unless fragments
        token = fragments.shift

        if token.match(/#{RE_SHORT_TOKEN_START}/)
          return parse_tree(token.gsub(/[\[:]/, ''), :short)
        end

        if token.match(/#{RE_LONG_TOKEN_START}/)
          return parse_tree(token.gsub(/[\[\]]/, ''), :long)
        end

        if token.match(/#{RE_HTML_TOKEN_START}/)
          return token if token.index('/>')
          return parse_tree(token.gsub(/[<>]/, '').split(' ').first, :html)
        end

        token.to_s
      end

      def parse_tree(name, type = :short)
        tree = [name]
        @tokens << name unless (@tokens.include?(name) or name == RESERVED_TOKEN)

        if type == :short
          first = true
          until fragments.first.nil? or fragments.first.match(/#{RE_SHORT_TOKEN_END}/)
            value = parse
            if first and value.is_a?(String)
              value = value.lstrip
              first = false
            end
            tree << value
          end
        elsif type == :long
          until fragments.first.nil? or fragments.first.match(/#{RE_LONG_TOKEN_END}/)
            tree << parse
          end
        elsif type == :html
          until fragments.first.nil? or fragments.first.match(/#{RE_HTML_TOKEN_END}/)
            tree << parse
          end
        end

        fragments.shift
        tree
      end

      def default_decoration(token_name, token_value)
        default_decoration = Tml.config.default_token_value(normalize_token(token_name), :decoration)

        unless default_decoration
          Tml.logger.error("Invalid decoration token value for #{token_name} in #{text}")
          return token_value
        end

        default_decoration = default_decoration.clone
        decoration_token_values = context[token_name.to_sym] || context[token_name.to_s]

        default_decoration.gsub!('{$0}', token_value.to_s)

        if decoration_token_values.is_a?(Hash)
          decoration_token_values.keys.each do |key|
            default_decoration.gsub!("{$#{key}}", decoration_token_values[key].to_s)
          end
        end

        default_decoration
      end

      def allowed_token?(token)
        return true if opts[:allowed_tokens].nil?
        opts[:allowed_tokens].include?(token)
      end

      def apply(token, value)
        return value if token == RESERVED_TOKEN
        return value unless allowed_token?(token)

        method = context[token.to_sym] || context[token.to_s]

        if method
          if method.is_a?(Proc)
            return method.call(value)
          end

          if method.is_a?(Array) or method.is_a?(Hash)
            return default_decoration(token, value)
          end

          if method.is_a?(String)
            return method.to_s.gsub('{$0}', value)
          end

          return value
        end

        if Tml.config.default_token_value(normalize_token(token), :decoration)
          return default_decoration(token, value)
        end

        value
      end

      def normalize_token(name)
        name.to_s.gsub(/(\d)*$/, '')
      end

      def evaluate(expr)
        unless expr.is_a?(Array)
          return expr
        end

        token = expr[0]
        args = expr.drop(1)
        value = args.map { |a| self.evaluate(a) }.join('')

        apply(token, value)
      end

      def substitute
        evaluate(parse).gsub('[/tml]', '')
      end

    end
  end
end
