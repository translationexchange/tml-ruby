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


module TmlExtensions
  module Array
    module TmlStuff
      attr_accessor :token_type
      attr_accessor :orig_token
      attr_accessor :token_obj
    end
  end
end


Array.include ::TmlExtensions::Array::TmlStuff


module Tml
  module Tokenizers
    class Tools

      def self.format_parsed_key(parsed_decoration_tokens, formatters)


        def self.process_sequence(sequence, formatters)
          to_flat = sequence.map do |tok|
            if tok.kind_of?(Array)
              tok.token_obj.full_name if tok.token_type == 'data'

              arr = [formatters[:start] ? formatters[:start].call(tok.orig_token) : tok.orig_token]
              arr.push(*tok[1..-1])

              end_tag = ']'
              case tok.token_type
                when :long
                  end_tag = "[/#{tok[0]}]"
                when :html
                  end_tag = "</#{tok[0]}>"
                else
              end
              arr.push(formatters[:end] ? formatters[:end].call(end_tag) : end_tag)
              self.process_sequence(arr, formatters)
            else
              tok
            end
          end

          return to_flat.flatten.join
        end

        self.process_sequence(parsed_decoration_tokens[1..-1], formatters)
      end

      def self.include_data_tokens(parsed_decoration_tokens, data_tokens)
        data_tokens.tokens.each { |data_tok| replace_in_sequence(parsed_decoration_tokens, data_tok) }
        parsed_decoration_tokens
      end

      def self.replace_in_sequence(arr, token)
        last_replaced_index = -1
        arr.each_with_index do |tok, index|
          next if last_replaced_index == index

          if tok.kind_of?(Array)
            replace_in_sequence(tok, token)
          else

            tok_index = tok.index(token.full_name)
            next if tok_index.nil?

            tok_arr = [token.name, token.name]
            tok_arr.token_type = 'data'
            tok_arr.token_obj = token

            out = []
            if tok_index > 0
              out.push(tok[0, tok_index])
            end
            out.push(tok_arr)

            if tok_index + token.full_name.length < tok.length
              out.push(tok[tok_index + token.full_name.length..-1])
            end

            arr[index,1] = out
            last_replaced_index = index + 1
          end
        end
      end
    end
  end
end

