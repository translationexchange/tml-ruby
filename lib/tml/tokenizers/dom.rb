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

require 'nokogiri'

module Tml
  module Tokenizers
    class Dom

      attr_accessor :context, :tokens, :options

      def initialize(context = {}, options = {})
        self.context = context
        self.options = options
        reset_context
      end

      def translate(doc)
        translate_tree(doc.is_a?(String) ? Nokogiri::HTML.fragment(doc) : doc)
      end

      def translate_tree(node)
        if non_translatable_node?(node)
          return node.inner_html
        end

        return translate_tml(node.inner_text) if node.type == 3

        html = ''
        buffer = ''

        node.children.each do |child|
          if child.type == 3
            buffer += child.inner_text
          elsif inline_node?(child) and has_inline_or_text_siblings?(child) and !between_separators?(child)
            buffer += generate_tml_tags(child)
          elsif separator_node?(child)
            html += translate_tml(buffer) if buffer != ''
            html += generate_html_token(child)
            buffer = ''
          else
            html += translate_tml(buffer) if buffer != ''

            container_value = translate_tree(child)
            if ignored_node?(child)
              html += container_value
            else
              html += generate_html_token(child, container_value)
            end

            buffer = ''
          end
        end

        html += translate_tml(buffer) if buffer != ''
        html
      end

      def non_translatable_node?(node)
        return false unless node
        return true if node.type == 1 && (option('nodes.scripts') || []).index(node.name.downcase)
        return true if node.type == 1 && node.children.length === 0 && node.inner_text == ''
        false
      end

      def translate_tml(tml)
        return tml if empty_string?(tml)
        tml = generate_data_tokens(tml)

        if option('split_sentences')
          sentences = Tml::Utils.split_sentences(tml)
          translation = tml
          sentences.each do |sentence|
            sentence_translation = option('debug') ? debug_translation(sentence) : Tml.session.current_language.translate(sentence, tokens, options)
            translation = translation.gsub(sentence, sentence_translation)
          end
          reset_context
          return translation
        end

        tml = tml.gsub(/[\n]/, '').gsub(/\s\s+/, ' ').strip

        translation = option('debug') ? debug_translation(tml) : Tml.session.target_language.translate(tml, tokens, options)
        reset_context
        translation
      end

      def has_child_nodes?(node)
        node.children and node.children.length > 0
      end

      def between_separators?(node)
        (separator_node?(node.previous_sibling) and !valid_text_node?(node.next_sibling)) or
        (separator_node?(node.next_sibling) and !valid_text_node?(node.previous_sibling))
      end

      def generate_tml_tags(node)
        buffer = ''
        node.children.each do |child|
          if child.type == 3
            buffer += child.inner_text
          else
            buffer += generate_tml_tags(child)
          end
        end

        token_context = generate_html_token(node)
        token = contextualize(adjust_name(node), token_context)
        value = sanitize_value(buffer)

        return '{' + token + '}' if self_closing_node?(node)
        return '[' + token + ': ' + value + ']' if short_token?(token, value)

        '[' + token + ']' + value + '[/' + token + ']'
      end

      def option(name)
        value = Tml::Utils.hash_value(self.options, name)
        value || Tml.config.translator_option(name)
      end

      def debug_translation(translation)
        option('debug_format').gsub('{$0}', translation)
      end

      def empty_string?(tml)
        tml = tml.gsub(/[\s\n\r\t]/, '')
        tml == ''
      end

      def reset_context
        self.tokens = {}.merge(self.context)
      end

      def short_token?(token, value)
        option('nodes.short').index(token.downcase) || value.length < 20
      end

      def only_child?(node)
        return false unless node.parent
        node.parent.children.count == 1
      end

      def has_inline_or_text_siblings?(node)
        return false unless node.parent

        node.parent.children.each do |child|
          unless child == node
            return true if inline_node?(child) || valid_text_node?(child)
          end
        end

        false
      end

      def inline_node?(node)
        (
          node.type == 1 and
          (option('nodes.inline') || []).index(node.name.downcase) and
          !only_child?(node)
        )
      end

      def container_node?(node)
        node.type == 1 && !inline_node?(node)
      end

      def self_closing_node?(node)
        !node.children || !node.children.first
      end
    
      def ignored_node?(node)
        return true if (node.type != 1)
        (option('nodes.ignored') || []).index(node.name.downcase)
      end

      def valid_text_node?(node)
        return false unless node
        node.type == 3 && !empty_string?(node.inner_text)
      end

      def separator_node?(node)
        return false unless node
        node.type == 1 && (option('nodes.splitters') || []).index(node.name.downcase)
      end

      def sanitize_value(value)
        value.gsub(/^\s+/, '')
      end

      def generate_data_tokens(text)
        if option('data_tokens.special.enabled')
          matches = text.scan(option('data_tokens.special.regex'))
          matches.each do  |match|
            token = match[1, - 2]
            self.context[token] = match
            text = text.gsub(match, "{#{token}}")
          end
        end

        if option('data_tokens.date.enabled')
          token_name = option('data_tokens.date.name')
          formats = option('data_tokens.date.formats')
          formats.each do |format|
            regex = format[0]
            # date_format = format[1]

            matches = text.scan(regex)
            if matches
              matches.each do |match|
                next if match.first.nil? or match.first == ''
                date = match.first
                token = self.contextualize(token_name, date)
                replacement = "{#{token}}"
                text = text.gsub(date, replacement)
              end
            end
          end
        end

        rules = option('data_tokens.rules')
        if rules
          rules.each do |rule|
            if rule[:enabled]
              matches = text.scan(rule[:regex])

              if matches
                matches.each do |match|
                  next if match.first.nil? or match.first == ''
                  value = match.first.strip

                  unless value == ''
                    token = contextualize(rule[:name], value.gsub(/[.,;\s]/, '').to_i)
                    text = text.gsub(value, value.gsub(value, "{#{token}}"))
                  end
                end
              end
            end
          end
        end

        text
      end

      def generate_html_token(node, value = nil)
        name = node.name.downcase
        attributes = node.attributes
        attributes_hash = {}
        value = (!value ? '{$0}' : value)

        if attributes.length == 0
          if self_closing_node?(node)
            return '<' + name + '/>' if %w(br hr).index(name)
            return '<' + name + '>' + '</' + name + '>'
          end
          return '<' + name + '>' + value + '</' + name + '>'
        end

        attributes.each do |name, attribute|
          attributes_hash[name] = attribute.value
        end

        keys = attributes_hash.keys.sort

        attr = []
        keys.each do |key|
          quote = attributes_hash[key].index("'") ? '"' : "'"
          attr << (key + '=' + quote + attributes_hash[key] + quote)
        end
        attr = attr.join(' ')

        return '<' + name + ' ' + attr + '>' + '</' + name + '>' if self_closing_node?(node)
        '<' + name + ' ' + attr + '>' + value + '</' + name + '>'
      end

      def adjust_name(node)
        name = node.name.downcase
        map = option('name_mapping')
        map[name.to_sym] ? map[name.to_sym] : name
      end

      def contextualize(name, context)
        if self.tokens[name] and self.tokens[name] != context
          index = 0
          matches = name.match(/\d+$/)
          if matches and matches.length > 0
            index = matches[matches.length-1].to_i
            name = name.gsub(index.to_s, '')
          end
          name += (index + 1).to_s
          return contextualize(name, context)
        end

        self.tokens[name] = context
        name
      end

      def debug(doc)
        self.doc = doc
        debug_tree(self.doc, 0)
      end

      def debug_tree(node, depth)
        padding = ('=' * (depth+1))

        Tml.logger.log(padding + '=> ' + (node) + ': ' + node_info(node))

        (node.children || []).each do |child|
          debug_tree(child, depth+1)
        end
      end

      def node_info(node)
        info = []
        info << node.type

        info << node.tagName if node.type == 1

        if inline_node?(node)
          info << 'inline'
          if has_inline_or_text_siblings?(node)
            info << 'sentence'
          else
            info << 'only translatable'
          end
        end

        info << 'self closing' if self_closing_node?(node)
        info << 'only child' if only_child?(node)

        return "[#{info.join(', ')}]: " + node.inner_text if node.type == 3
        "[#{info.join(', ')}]"
      end

    end
  end
end