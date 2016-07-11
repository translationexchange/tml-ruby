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
    class Data

      attr_reader :label, :full_name, :token_type, :short_name, :case_keys, :context_keys

      def self.expression
        /(%?\{{1,2}\s*\w+\s*(:\s*\w+)*\s*(::\s*\w+)*\s*\}{1,2})/
      end

      def self.parse(label, opts = {})
        tokens = []
        label.scan(expression).uniq.each do |token_array|
          tokens << self.new(label, token_array.first)
        end
        tokens
      end

      def initialize(label, token)
        @label = label
        @full_name = token
        @token_type = self.class.name.split('::').last
        parse_elements
      end

      def parse_elements
        name_without_parens = @full_name.gsub(/^%/, '')[1..-2]
        name_without_case_keys = name_without_parens.split('::').first.strip

        @short_name = name_without_parens.split(':').first.strip
        @case_keys = name_without_parens.scan(/(::\w+)/).flatten.uniq.collect{|c| c.gsub('::', '')}
        @context_keys = name_without_case_keys.scan(/(:\w+)/).flatten.uniq.collect{|c| c.gsub(':', '')}
      end

      def name(opts = {})
        val = short_name
        val = "#{val}:#{context_keys.join(':')}" if opts[:context_keys] and context_keys.any?
        val = "#{val}::#{case_keys.join('::')}" if opts[:case_keys] and case_keys.any?
        val = "{#{val}}" if opts[:parens]
        val
      end

      def key
        short_name.to_sym
      end

      # used by the translator submit dialog
      def name_for_case_keys(keys)
        keys = [keys] unless keys.is_a?(Array)
        "#{name}::#{keys.join('::')}"
      end

      def context_for_language(language)
        if context_keys.any?
          language.context_by_keyword(context_keys.first)
        else
          language.context_by_token_name(short_name)
        end
      end

      # Utility method for errors
      def error(msg, return_token = true)
        Tml.logger.error(msg)
        return_token ? full_name : label
      end

      ##############################################################################
      #
      # returns token object from tokens param
      #
      ##############################################################################

      def self.token_object(token_values, token_name)
        return nil if token_values.nil?
        token_object = Tml::Utils.hash_value(token_values, token_name)
        return token_object.first if token_object.is_a?(Array)
        if token_object.is_a?(Hash)
          object = Tml::Utils.hash_value(token_object, :object)
          return object if object
        end
        token_object
      end

      ##############################################################################
      #
      # tr("Hello {user_list}!", "", {:user_list => [[user1, user2, user3], :name]}}
      #
      # first element is an array, the rest of the elements are similar to the
      # regular tokens lambda, symbol, string, with parameters that follow
      #
      # if you want to pass options, then make the second parameter an array as well
      #
      # tr("{users} joined the site", {:users => [[user1, user2, user3], :name]})
      #
      # tr("{users} joined the site", {:users => [[user1, user2, user3], lambda{|user| user.name}]})
      #
      # tr("{users} joined the site", {:users => [[user1, user2, user3], {:attribute => :name})
      #
      # tr("{users} joined the site", {:users => [[user1, user2, user3], {:attribute => :name, :value => "<strong>{$0}</strong>"})
      #
      # tr("{users} joined the site", {:users => [[user1, user2, user3], "<strong>{$0}</strong>")
      #
      # tr("{users} joined the site", {:users => [[user1, user2, user3], :name, {
      #   :limit => 4,
      #   :separator => ', ',
      #   :joiner => 'and',
      #   :remainder => lambda{|elements| tr("#{count||other}", :count => elements.size)},
      #   :translate => false,
      #   :expandable => true,
      #   :collapsable => true
      # })
      #
      #
      ##############################################################################
      def token_values_from_array(params, language, options)
        list_options = {
         :description => "List joiner",
         :limit => 4,
         :separator => ", ",
         :joiner => 'and',
         :less => '{laquo} less',
         :expandable => true,
         :collapsable => true
        }

        objects = params[0]
        method = params[1]
        list_options.merge!(params[2]) if params.size > 2
        list_options[:expandable] = false if options[:skip_decorations]

        values = objects.collect do |obj|
          if method.is_a?(String)
            element = method.gsub("{$0}", sanitize(obj.to_s, obj, language, options.merge(:safe => false)))
          elsif method.is_a?(Symbol)
            if obj.is_a?(Hash)
              value = Tml::Utils.hash_value(obj, method)
            else
              value = obj.send(method)
            end
            element = sanitize(value, obj, language, options.merge(:safe => false))
          elsif method.is_a?(Hash)
            attr = Tml::Utils.hash_value(method, :attribute) || Tml::Utils.hash_value(method, :property)
            if obj.is_a?(Hash)
              value = Tml::Utils.hash_value(obj, attr)
            else
              value = obj.send(method)
            end

            hash_value = Tml::Utils.hash_value(method, :value)
            if hash_value
              element = hash_value.gsub("{$0}", sanitize(value, obj, language, options.merge(:safe => false)))
            else
              element = sanitize(value, obj, language, options.merge(:safe => false))
            end
          elsif method.is_a?(Proc)
            element = sanitize(method.call(obj), obj, language, options.merge(:safe => true))
          end

          Tml::Decorators::Base.decorator.decorate_element(self, element, options)
        end

        return values.first if objects.size == 1
        return values.join(list_options[:separator]) if list_options[:joiner].nil? || list_options[:joiner] == ""

        joiner = language.translate(list_options[:joiner], list_options[:description], {}, options)
        if values.size <= list_options[:limit]
          return "#{values[0..-2].join(list_options[:separator])} #{joiner} #{values.last}"
        end

        display_ary = values[0..(list_options[:limit]-1)]
        remaining_ary = values[list_options[:limit]..-1]
        result = "#{display_ary.join(list_options[:separator])}"

        unless list_options[:expandable]
          result << " " << joiner << " "
          if list_options[:remainder] and list_options[:remainder].is_a?(Proc)
            result << list_options[:remainder].call(remaining_ary)
          else
            result << language.translate("{count||other}", list_options[:description], {:count => remaining_ary.size}, options)
          end
          return result
        end

        uniq_id = Tml::TranslationKey.generate_key(label, values.join(","))
        result << "<span id=\"tml_other_link_#{uniq_id}\"> #{joiner} "

        result << "<a href='#' onClick=\"document.getElementById('tml_other_link_#{uniq_id}').style.display='none'; document.getElementById('tml_other_elements_#{uniq_id}').style.display='inline'; return false;\">"
        if list_options[:remainder] and list_options[:remainder].is_a?(Proc)
          result << list_options[:remainder].call(remaining_ary)
        else
          result << language.translate("{count||other}", list_options[:description], {:count => remaining_ary.size}, options)
        end
        result << "</a></span>"

        result << "<span id=\"tml_other_elements_#{uniq_id}\" style='display:none'>"
        result << list_options[:separator] << " "
        result << remaining_ary[0..-2].join(list_options[:separator])
        result << " #{joiner} "
        result << remaining_ary.last

        if list_options[:collapsable]
          result << "<a href='#' style='font-size:smaller;white-space:nowrap' onClick=\"document.getElementById('tml_other_link_#{uniq_id}').style.display='inline'; document.getElementById('tml_other_elements_#{uniq_id}').style.display='none'; return false;\"> "
          result << language.translate(list_options[:less], list_options[:description], {}, options)
          result << "</a>"
        end

        result << "</span>"
      end

      ##############################################################################
      #
      # gets the value based on various evaluation methods
      #
      # examples:
      #
      # tr("Hello {user}", {:user => [current_user, current_user.name]}}
      # tr("Hello {user}", {:user => [current_user, :name]}}
      #
      # tr("Hello {user}", {:user => [{:name => "Michael", :gender => :male}, current_user.name]}}
      # tr("Hello {user}", {:user => [{:name => "Michael", :gender => :male}, :name]}}
      #
      ##############################################################################

      def token_value_from_array_param(array, language, options)
        # if you provided an array, it better have some values
        if array.size < 2
          return sanitize(array[0], array[0], language, options.merge(:safe => false))
        end

        # if the first value of an array is an array handle it here
        if array[0].is_a?(Array)
          return token_values_from_array(array, language, options)
        end

        if array[1].is_a?(String)
          return sanitize(array[1], array[0], language, options.merge(:safe => true))
        end

        if array[0].is_a?(Hash)
          if array[1].is_a?(Symbol)
            return sanitize(Tml::Utils.hash_value(array[0], array[1]), array[0], language, options.merge(:safe => false))
          end

          return error("Invalid value for array token #{full_name} in #{label}")
        end

        # if second param is symbol, invoke the method on the object with the remaining values
        if array[1].is_a?(Symbol)
          return sanitize(array[0].send(array[1]), array[0], language, options.merge(:safe => false))
        end

        # if second param is a lambda
        if array[1].is_a?(Proc)
          return sanitize(array[1].call(array[0]), array[0], language, options.merge(:safe => false))
        end

        error("Invalid value for array token #{full_name} in #{label}")
      end

      ##############################################################################
      #
      # Hashes are often used with JSON structures. We can be smart about how to pull default values.
      #
      # examples:
      #
      # tr("Hello {user}", {:user => {:name => "Michael", :gender => :male}}}
      #
      # tr("Hello {user}", {:user => {:object => {:gender => :male}, :value => "Michael"}}}
      # tr("Hello {user}", {:user => {:object => {:name => "Michael", :gender => :male}, :property => :name}}}
      # tr("Hello {user}", {:user => {:object => {:name => "Michael", :gender => :male}, :attribute => :name}}}
      #
      # tr("Hello {user}", {:user => {:object => user, :value => "Michael"}}}
      # tr("Hello {user}", {:user => {:object => user, :property => :name}}}
      # tr("Hello {user}", {:user => {:object => user, :attribute => :name}}}
      #
      ##############################################################################

      def token_value_from_hash_param(hash, language, options)
        value = Tml::Utils.hash_value(hash, :value)
        [:name, :first_name, :display_name, :full_name, :username].each do |attr|
          value ||= Tml::Utils.hash_value(hash, attr)
        end

        attr  = Tml::Utils.hash_value(hash, :attribute) || Tml::Utils.hash_value(hash, :property)
        value ||= Tml::Utils.hash_value(hash, attr)

        object = Tml::Utils.hash_value(hash, :object)

        unless value.nil?
          return sanitize(value, object || hash, language, options.merge(:safe => true))
        end

        if object.nil?
          return error("Missing value for hash token #{full_name} in #{label}")
        end

        if object.is_a?(Hash)
          unless attr.nil?
            return sanitize(Tml::Utils.hash_value(object, attr), object, language, options.merge(:safe => false))
          end

          return error("Missing value for hash token #{full_name} in #{label}")
        end

        sanitize(object.send(attr), object, language, options.merge(:safe => false))
      end

      # evaluate all possible methods for the token value and return sanitized result
      def token_value(object, language, options = {})
        return token_value_from_array_param(object, language, options) if object.is_a?(Array)
        return token_value_from_hash_param(object, language, options) if object.is_a?(Hash)
        sanitize(object, object, language, options)
      end

      def sanitize(value, object, language, options)
        value = value.to_s

        unless Tml.session.block_option(:skip_html_escaping)
          if options[:safe] == false
            value = CGI.escapeHTML(value)
          end
        end

        return value unless language_cases_enabled?
        apply_language_cases(value, object, language, options)
      end

      def language_cases_enabled?
        Tml.session.application and Tml.session.application.feature_enabled?(:language_cases)
      end

      ##############################################################################
      #
      # chooses the appropriate case for the token value. case is identified with ::
      #
      # examples:
      #
      # tr("Hello {user::nom}", "", :user => current_user)
      # tr("{actor} gave {target::dat} a present", "", :actor => user1, :target => user2)
      # tr("This is {user::pos} toy", "", :user => current_user)
      #
      ##############################################################################
      def apply_case(key, value, object, language, options)
        lcase = language.case_by_keyword(key)
        return value unless lcase
        lcase.apply(value, object, options)
      end

      def apply_language_cases(value, object, language, options)
        case_keys.each do |key|
          value = apply_case(key, value, object, language, options)
        end

        value
      end

      def substitute(label, context, language, options = {})
        # get the object from the values
        object = Tml::Utils.hash_value(context, key)

        # see if the token is a default html token
        object = Tml.config.default_token_value(key) if object.nil?

        if object.nil? and not context.key?(key)
          return error("Missing value for #{full_name} in #{label}", false)
        end

        return label.gsub(full_name, '') if object.nil?

        value = token_value(object, language, options)
        label.gsub(full_name, decorate(value, options))
      end

      def decorate(value, options = {})
        Tml::Decorators::Base.decorator.decorate_token(self, value, options)
      end

      def sanitized_name
        name(:parens => true)
      end

      def decoration_name
        self.class.name.split('::').last.downcase
      end

      def to_s
        full_name
      end
    end
  end
end
