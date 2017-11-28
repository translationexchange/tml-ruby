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
#
#######################################################################

module Tml
  module Tokenizers
    class XMessage

      attr_accessor :label, :pos, :len, :last, :options, :tree

      def optional_style_format_types
        @optional_style_format_types ||= {
            'text' => true,
            'date' => true,
            'time' => true,
            'number' => true,
            'name' => true,
            'list' => true,
            'possessive' => true,
            'salutation' => true
        }
      end

      def initialize(text, opts = {})
        @label = text
        @pos = 0
        @len = @label ? @label.length : 0
        @last = nil
        @options = opts || {}
        @tree = nil
        tokenize
      end

      def update_last
        @last = @pos > 0 ? @label[@pos - 1] : nil
      end

      def next_char
        return if @len == 0 || @pos >= @len
        update_last
        @pos += 1
        @label[@pos - 1]
      end

      def peek_char
        return if @len == 0
        @label[@pos]
      end

      def revert
        if (@pos > 0)
          @pos -= 1
          update_last
        end
      end

      def escaped?
        @last && @last == '\\'
      end

      def no_format_style(result, c, argument_index, format_type)
        raise "no format style allowed for format type '" + format_type + "'";
      end

      def collection_format_style(result, c, argument_index, format_type)
        # register the format element
        styles = []
        subtype = 'text'; # default

        if c == ','
          # we have a sub-type
          subtype = ''
          c = next_char
          while c && !',}'.index(c)
            subtype += c
            c = next_char
            unless c
              raise "expected ',' or '}', but found end of string"
            end
          end
        end

        result << {index: argument_index, type: format_type, subtype: subtype, styles: styles}

        if c == '}'
          return
        end

        # parse format style
        while c
          c = next_char
          unless c
            raise "expected '}', '|' or format style value, but found end of string"
          end

          if c == '}' && !escaped?
            return
          elsif c == '|'
            next
          end

          style_key = ''
          while c && !'#<|}'.index(c)
            style_key += c
            c = next_char
            unless c
              raise "expected '#', '<' or '|', but found end of string"
            end
          end

          if c == '<'
            style_key += c
          end

          items = []
          styles << {key: style_key, items: items}

          if '#<'.index(c)
            traverse_text(items)
          elsif '|}'.index(c)
            # we found a key without value e.g. {0,param,possessive} and {0,param,prefix#.|possessive}
            revert
          end
        end
      end

      def text_format_style(result, c, argument_index, format_type)
        # parse format style
        buffer = ''
        c = next_char
        unless c
          raise "expected format style or '}', but found end of string"
        end

        while c
          if c == '}'
            result << {index: argument_index, type: format_type, value: buffer}
            return
          end

          # keep adding to buffer
          buffer += c
          c = next_char
          unless c
            raise "expected '}', but found end of string"
          end
        end
      end

      def default_format_style(result, c, argument_index, format_type)
        # register the format element
        styles = []
        result << {index: argument_index, type: format_type, styles: styles}

        # parse format style
        while c
          c = next_char
          unless c
            raise "expected '}', '|' or format style value, but found end of string"
          end

          if c == '}' && !escaped?
            return
          elsif c == '|'
            next
          end

          style_key = ''
          while c && !'#<+|}'.index(c)
            style_key += c
            c = next_char
            unless c
              raise "expected '#', '<', '+' or '|', but found end of string"
            end
          end

          if c == '<' || c == '+'
            style_key += c
          end

          items = []
          styles << {key: style_key, items: items}

          if '#<+'.index(c)
            traverse_text(items)
          elsif '|}'.index(c)
            # we found a key without value e.g. {0,param,possessive} and {0,param,prefix#.|possessive}
            revert
          end
        end
      end

      def traverse_format_element(result)
        argument_index = -1
        format_type = nil
        c = next_char

        unless c
          raise 'expected place holder index, but found end of string'
        end

        if c.match(/[\d:]/)
          # process argument index
          is_keyword = c == ':'
          index = ''
          while c && !',}'.index(c)
            index += c
            c = next_char
            unless c
              raise "expected ',' or '}', but found end of string";
            end
          end

          if !is_keyword && !index.match(/\d+/)
            throw "argument index must be numeric: #{index}"
          end

          argument_index = is_keyword ? index : index * 1
        end

        if c != '}'
          # process format type
          format_type = ''
          c = next_char
          unless c
            raise 'expected format type, but found end of string'
          end

          while c && !',}'.index(c) && !escaped?
            format_type += c
            c = next_char
            unless c
              raise "expected ',' or '}', but found end of string"
            end
          end
        end

        if c == '}' && !escaped?
          if format_type && optional_style_format_types[format_type]
            # we found {0,number} or {0,possessive} or {0,salutation}, which are valid expressions
            result << {type: format_type, index: argument_index}
          else
            if format_type
              # we found something like {0,<type>}, which is invalid.
              raise "expected format style for format type '#{format_type}'"
            end

            # push param format element
            result << {type: 'param', index: argument_index}
          end
        elsif c == ','
          processors = {
              list: 'collection_format_style',
              date: 'text_format_style',
              time: 'text_format_style',
              number: 'text_format_style',
              suffix: 'text_format_style',
              possessive: 'no_format_style',
              salutation: 'no_format_style',
              default: 'default_format_style'
          }
          processor = (processors[format_type.to_sym] || processors[:default])
          self.send(processor, result, c, argument_index, format_type)
        else
          raise "expected ',' or '}', but found '#{c}' at position #{@pos}"
        end
      end

      def traverse_text(result)
        in_quoted_string = false
        buffer = ''
        c = next_char

        while c do
          if c == "'"
            in_quoted_string = !in_quoted_string
          end

          if !in_quoted_string && c == '{' && !escaped?
            unless buffer.empty?
              result << {type: 'trans', value: buffer}
              buffer = ''
            end
            traverse_format_element(result)
          elsif !in_quoted_string && (c == '|' || c == '}') && !escaped?
            revert
            break
          else
            buffer += c
          end
          c = next_char
        end

        unless buffer.empty?
          result << {type: 'trans', value: buffer}
          buffer = ''
        end

        result
      end

      def tokenize
        result = []
        traverse_text(result)
        @tree = result
      rescue Exception => ex
        pp ex
        pp "Failed to parse the expression: " + @label
        @tree = nil
      end

      def rule_key(context_key, rule_key)
        return rule_key unless Tml.config.xmessage_rule_key_mapping[context_key.to_sym]
        Tml.config.xmessage_rule_key_mapping[context_key.to_sym][rule_key.to_sym] || rule_key
      end

      def choice(language, token, token_object)
        return unless token

        context_key = token.context_keys.first
        return unless context_key

        ctx = language.context_by_keyword(context_key)
        return unless ctx

        # pp context_key, token_object

        rule = ctx.find_matching_rule(token_object)
        if rule
          # pp context_key, rule.keyword
          return rule_key(context_key, rule.keyword)
        end

        nil
      end

      def data?(type)
        return false unless type
        %w(param number).include?(type)
      end

      def decoration?(type)
        return false unless type
        Tml.config.xmessage_decoration_tokens.include?(type.to_sym)
      end

      def choice?(type)
        type == 'choice'
      end

      def map?(type)
        type == 'map'
      end

      def compile(language, exp, buffer, params)
        style = nil

        exp.each do |el|
          token = token_by_type(el[:type], el)
          token_object = get_token_object(params, token)
          token_value = get_token_value(token_object, token, language)

          if el[:styles]
            if choice?(el[:type])
              key = choice(language, token, token_object)
              style = el[:styles].find{ |style|
                style[:key] == key
              }
              if style
                compile(language, style[:items], buffer, params)
              end
            elsif map?(el[:type])
              style = el[:styles].find{ |style|
                style[:key] == token_value
              }
              compile(language, style[:items], buffer, params)
            elsif decoration?(el[:type])
              buffer << token.open_tag(token_object)
              compile(language, el[:styles][0][:items], buffer, params)
              buffer << token.close_tag
            else
              compile(language, el[:styles][0][:items], buffer, params)
            end
          elsif data?(el[:type])
            buffer << token_value
          else
            buffer << el[:value]
          end
        end

        buffer
      end

      def tokens
        @tokens ||= begin
          tokens = []
          extract_tokens(tree, tokens)
          tokens.uniq{ |t| [t.class.name, t.full_name] }
        end
      end

      def token_by_type(type, data)
        if decoration?(type)
          Tml::Tokens::XMessage::Decoration.new(label, data)
        elsif data?(type)
          Tml::Tokens::XMessage::Data.new(label, data)
        elsif choice?(type)
          Tml::Tokens::XMessage::Choice.new(label, data)
        elsif map?(type)
          return Tml::Tokens::XMessage::Map.new(label, data)
        else
          nil
        end
      end

      def extract_tokens(tree, tokens)
        tree.each do |fragment|
          token = token_by_type(fragment[:type], fragment)
          tokens << token if token
          if fragment[:items]
            extract_tokens(fragment[:items], tokens)
          elsif fragment[:styles]
            extract_tokens(fragment[:styles], tokens)
          end
        end
      end

      def get_token_object(token_values, token)
        return nil unless token
        token.token_object(token_values)
      end

      def get_token_value(token_object, token, language)
        return nil unless token_object && token
        token.token_value(token_object, language)
      end

      def substitute(language, tokens = {}, options = {})
        return @label unless tree
        compile(language, tree, [], tokens).join('')
      end

    end
  end
end
