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

class Tml::Decorators::Html < Tml::Decorators::Base

  def decorate(translated_label, translation_language, target_language, translation_key, options = {})
    #Tml.logger.info("Decorating #{translated_label} of #{translation_language.locale} to #{target_language.locale}")

    # skip decoration if instructed so
    return translated_label if options[:skip_decorations]

    # if translation key language is the same as target language - skip decorations
    return translated_label if translation_key.language == target_language
    return translated_label unless inline_mode?
    return translated_label if translation_key.locked? and not Tml.session.current_translator.manager?

    classes = %w(tml_translatable)
    
    if translation_key.locked?
      # must be a manager and enabling locking feature
      # return translated_label unless Tml.session.current_translator.feature_enabled?(:show_locked_keys)
      classes << 'tml_locked'
    elsif translation_language == translation_key.language
      classes << 'tml_not_translated'
    elsif translation_language == target_language
      classes << 'tml_translated'
    else
      classes << 'tml_fallback'
    end

    element = 'span'
    element = 'div' if options[:use_div]

    html = "<#{element} class='#{classes.join(' ')}' data-translation_key='#{translation_key.key}' data-target_locale='#{target_language.locale}'>"
    html << translated_label
    html << "</#{element}>"
    html
  end

  def decorate_language_case(language_case, rule, original, transformed, options = {})
    return transformed if options[:skip_decorations] or language_case.language.default?
    return transformed unless inline_mode?

    data = {
      'keyword'       => language_case.keyword,
      'language_name' => language_case.language.english_name,
      'latin_name'    => language_case.latin_name,
      'native_name'   => language_case.native_name,
      'conditions'    => (rule ? rule.conditions : ''),
      'operations'    => (rule ? rule.operations : ''),
      'original'      => original,
      'transformed'   => transformed
    }

    attrs = []
    {
      'class'             => 'tml_language_case',
      'data-locale'       => language_case.language.locale,
      'data-rule'         => CGI::escape(Base64.encode64(data.to_json).gsub("\n", ''))
    }.each do |key, value|
      attrs << "#{key}=\"#{value.to_s.gsub('"', "\"")}\""
    end

    element = 'span'
    element = 'div' if options[:use_div]

    html = "<#{element} #{attrs.join(' ')}>"
    html << transformed
    html << "</#{element}>"
    html
  end

end