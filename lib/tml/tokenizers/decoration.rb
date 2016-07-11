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

module TmlExtensions
  module Array
    module TmlStuff
      attr_accessor :token_type
      attr_accessor :orig_token
      attr_accessor :full_token
      attr_accessor :parent_node
    end
  end
end


Array.include ::TmlExtensions::Array::TmlStuff

class TmlCloseTagError < StandardError
  attr_accessor :full_token
  attr_accessor :err_tree
  def initialize(message)
    super(message)
  end
end



module Tml
  module Tokenizers

    class TokenArray < Array
      attr_accessor :token_type
      attr_accessor :orig_token
      attr_accessor :full_token
      attr_accessor :parent_node
    end

    class Decoration

      attr_reader :tokens, :fragments, :context, :text, :opts

      RESERVED_TOKEN       = 'tml'

      RE_SHORT_TOKEN_START = '\[[\w]*:'
      RE_SHORT_TOKEN_END   = '\]'
      RE_LONG_TOKEN_START  = '\[[\w]*\]'                       # [link]
      RE_LONG_TOKEN_END    = '\[\/[\w]*\]'                     # [/link]
      RE_LONG_TOKEN1_END    = '\[\/([\w]*)\]'                     # [/link]
      RE_HTML_TOKEN_START  = '<[^\>]*>'                        # <link>
      RE_HTML_TOKEN1_END    = '<\/([^\>]*)>'                      # </link>
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
        re = '(' + [RE_SHORT_TOKEN_START,
              RE_SHORT_TOKEN_END,
              RE_LONG_TOKEN_START,
              RE_LONG_TOKEN1_END,
              RE_HTML_TOKEN_START,
              RE_HTML_TOKEN1_END,
              RE_TEXT].join('|') + ')'
        @fragments = text.scan(/#{re}/).map{|i| i.kind_of?(Array) ? i.shift : i }
        @tokens = []
      end

      def parse(parent_node = nil)
        return @text unless fragments
        token = fragments.shift

        if token.match(/#{RE_SHORT_TOKEN_START}/)
          name = token.gsub(/[\[:]/, '')
          return token unless name

          return parse_tree(name, :short, parent_node, token)
        end

        if token.match(/#{RE_LONG_TOKEN_START}/)
          name = token.gsub(/[\[\]]/, '')
          return token unless name
          return parse_tree(name, :long, parent_node, token)
        end

        if token.match(/#{RE_HTML_TOKEN_START}/)
          return token if token.index('/>')
          name = token.gsub(/[<>]/, '').split(' ').first
          return token unless name
          return parse_tree(name, :html, parent_node, token)
        end

        token.to_s
      end

      def get_tag_type(fragment, preferred_pattern, have_short_parents)
        return unless fragment

        if preferred_pattern
          match = fragment.scan(preferred_pattern)
          return { match: match, type: "preferred" } if match.any?
        end

        token_defs = [['html', /(#{RE_HTML_TOKEN1_END})/], ['long', /(#{RE_LONG_TOKEN1_END})/], ['short', /#{RE_SHORT_TOKEN_END}/]]


        token_defs.each do |tok|
          match = fragment.scan(tok[1])
          return { match: match[0], type: tok[0] } if match.any? && tok[0] != 'short'
          return { match: match, type: tok[0] } if match.any? && (tok[0] == 'short' && have_short_parents)
        end
        nil
      end

      def parse_tree(name, type, parent_node, orig_token)
        tree = [name]
        tree.token_type = type
        tree.orig_token = orig_token
        tree.parent_node = parent_node
        tree.full_token = type.to_s + '.' + name

        @tokens << name unless (@tokens.include?(name) or name == RESERVED_TOKEN)

        if type == :long
          end_tag = /\[\/\s*#{name}\s*\]/
        elsif type == :html
          end_tag = /<\/\s*#{name}\s*>/
        else
          end_tag = /#{RE_SHORT_TOKEN_END}/
        end

        have_short_parents = false
        temp_parent = parent_node
        while temp_parent
          if temp_parent.token_type == :short
            have_short_parents = true
            break
          end
          temp_parent = temp_parent.parent_node
        end

        match_any_end = -> (pattern = nil) {
          @current = fragments.first
          tag_match = get_tag_type(@current, pattern || end_tag, have_short_parents)
          return unless tag_match

          if tag_match[:type] == 'preferred'
            return tag_match[:match]
          else
            temp_parent = tree.parent_node
            while temp_parent
              if tag_match[:type] == 'short'
                full_name = nil
              else
                full_name = tag_match[:type] + '.' + tag_match[:match][1] || '' # doesn't work with short
              end

              matched_parent = tag_match[:type] != 'short' ? full_name == temp_parent.full_token : temp_parent.token_type == :short

              if matched_parent
                error = TmlCloseTagError.new("Could not find close tag, instead found parent #{temp_parent.full_token}")
                error.err_tree = tree
                error.full_token = tag_match[:match][1] ? full_name : temp_parent.full_token
                raise error
              end

              temp_parent = temp_parent.parent_node
            end
          end
        }
        end_match = nil
        end_matched = false

        begin
          if type == :short
            first = true
            while fragments.first && !(end_match = match_any_end.(/^\]$/))
              value = parse(tree)
              if first and value.is_a?(String)
                value = value.lstrip
                first = false
              end
              tree << value
            end
            if end_match
              end_matched = true
            end
          else
            while fragments.first && !(end_match = match_any_end.())
             tree << parse(tree)
            end
            if end_match
              end_matched = true
            end
          end
        rescue TmlCloseTagError => err
          if err.full_token == tree.full_token && tree != err.err_tree
            tree.push(*err.err_tree)
          else
            if tree != err.err_tree
              tree.push(*err.err_tree)
            end
            err.err_tree = tree
            tree[0] = tree.orig_token
            raise err
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
