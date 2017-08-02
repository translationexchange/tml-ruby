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
# Transform Token Form
#
# {count:number || one: message, many: messages} 
# {count:number || one: сообщение, few: сообщения, many: сообщений, other: много сообщений}   in other case the number is not displayed#
#
# {count | message}   - will not include {count}, resulting in "messages" with implied {count}
# {count | message, messages} 
#
# {count:number | message, messages} 
#
# {user:gender | he, she, he/she}
#
# {user:gender | male: he, female: she, other: he/she}
#
# {now:date | did, does, will do}
# {users:list | all male, all female, mixed genders}
#
# {count || message, messages}  - will include count:  "5 messages" 
# 
####################################################################### 

class Tml::Tokens::Transform < Tml::Tokens::Data
  attr_reader :pipe_separator, :piped_params

  def self.expression
    /(%?\{{1,2}\s*[\w]+\s*(:\s*\w+)*\s*\|\|?[^\{\}\|]+\}{1,2})/
  end

  def parse_elements
    name_without_parens = @full_name.gsub(/^%/, '')[1..-2]
    name_without_pipes = name_without_parens.split('|').first.strip
    name_without_case_keys = name_without_pipes.split('::').first.strip

    @short_name = name_without_pipes.split(':').first.strip
    @case_keys = name_without_pipes.scan(/(::\w+)/).flatten.uniq.collect{|c| c.gsub('::', '')}
    @context_keys = name_without_case_keys.scan(/(:\w+)/).flatten.uniq.collect{|c| c.gsub(':', '')}
    @pipe_separator = (full_name.index('||') ? '||' : '|')
    @piped_params = name_without_parens.split(pipe_separator).last.split(",").collect{|param| param.strip}
  end

  def displayed_in_translation?
    pipe_separator == "||"
  end

  def implied?
    not displayed_in_translation?
  end

  def prepare_label_for_suggestion(label, index, language)
    context = context_for_language(language)
    values = generate_value_map(piped_params, context)

    label.gsub(full_name, values[context.default_rule] || values.values.first)
  end

  # token:      {count|| one: message, many: messages}
  # results in: {"one": "message", "many": "messages"}
  #
  # token:      {count|| message}
  # transform:  [{"one": "{$0}", "other": "{$0::plural}"}, {"one": "{$0}", "other": "{$1}"}]
  # results in: {"one": "message", "other": "messages"}
  #
  # token:      {count|| message, messages}
  # transform:  [{"one": "{$0}", "other": "{$0::plural}"}, {"one": "{$0}", "other": "{$1}"}]
  # results in: {"one": "message", "other": "messages"}
  #
  # token:      {user| Dorogoi, Dorogaya}
  # transform:  ["unsupported", {"male": "{$0}", "female": "{$1}", "other": "{$0}/{$1}"}]
  # results in: {"male": "Dorogoi", "female": "Dorogaya", "other": "Dorogoi/Dorogaya"}
  #
  # token:      {actors || likes, like}
  # transform:  ["unsupported", {"one": "{$0}", "other": "{$1}"}]
  # results in: {"one": "likes", "other": "like"}
  def generate_value_map(params, context)
    values = {}

    if params.first.index(':')
      params.each do |p|
        nv = p.split(':')
        values[nv.first.strip] = nv.last.strip
      end
      return values
    end

    unless context.token_mapping
      error("The token context #{context.keyword} does not support transformation for unnamed params: #{full_name}")
      return nil
    end

    token_mapping = context.token_mapping

    # "unsupported"
    if token_mapping.is_a?(String)
      error("The token mapping #{token_mapping} does not support #{params.size} params: #{full_name}")
      return nil
    end

    # ["unsupported", "unsupported", {}]
    if token_mapping.is_a?(Array)
      if params.size > token_mapping.size
        error("The token mapping #{token_mapping} does not support #{params.size} params: #{full_name}")
        return nil
      end
      token_mapping = token_mapping[params.size-1]
      if token_mapping.is_a?(String)
        error("The token mapping #{token_mapping} does not support #{params.size} params: #{full_name}")
        return nil
      end
    end

    # {}
    token_mapping.each do |key, value|
      values[key] = value
      value.scan(/({\$\d(::\w+)*})/).each do |matches|
        token = matches.first
        parts = token[1..-2].split('::')
        index = parts.first.gsub('$', '').to_i

        if params.size < index
          error("The index inside #{context.token_mapping} is out of bound: #{full_name}")
          return nil
        end

        # apply settings cases
        value = params[index]
        if language_cases_enabled?
          parts[1..-1].each do |case_key|
            lcase = context.language.case_by_keyword(case_key)
            unless lcase
              error("Language case #{case_key} for context #{context.keyword} is not defined: #{full_name}")
              return nil
            end
            value = lcase.apply(value)
          end
        end
        values[key] = values[key].gsub(token, value)
      end
    end

    values
  end

  def substitute(label, context, language, options = {})
    object = self.class.token_object(context, key)

    unless object
      return error("Missing value for a token \"#{key}\" in \"#{label}\"", false)
    end

    if piped_params.empty?
      return error("Piped params may not be empty for token \"#{key}\" in \"#{label}\"", false)
    end

    language_context = context_for_language(language)

    unless language_context
      return error("Unknown context for a token: #{full_name} in #{language.locale}", false)
    end

    piped_values = generate_value_map(piped_params, language_context)

    unless piped_values
      return error("Failed to generate value map for: #{full_name} in #{language.locale}", false)
    end

    rule = language_context.find_matching_rule(object)
    return label unless rule

    value = piped_values[rule.keyword]
    if value.nil? and language_context.fallback_rule
      value = piped_values[language_context.fallback_rule.keyword]
    end

    return label unless value

    decorated_value = decorate(token_value(Tml::Utils.hash_value(context, key), language, options), options)

    substitution_value = []
    if displayed_in_translation?
      substitution_value << decorated_value
      substitution_value << ' '
    else
      value = value.gsub("##{short_name}#", decorated_value)
    end
    substitution_value << value

    label.gsub(full_name, substitution_value.join(''))
  end

  def decoation_name
    'piped'
  end

end
