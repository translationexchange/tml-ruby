#--
# Copyright (c) 2016 Translation Exchange Inc. http://translationexchange.com
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

class Array

  # translates an array of options for a select tag
  def translate_options(description = '', options = {})
    return [] if empty?

    options = options.merge(:skip_decorations => true)

    collect do |opt|
      if opt.is_a?(Array) and opt.first.is_a?(String) 
        [opt.first.translate(description, {}, options), opt.last]
      elsif opt.is_a?(String)
        [opt.translate(description, {}, options), opt]
      else  
        opt
      end
    end
  end
  alias_method :tro, :translate_options

  # translates and joins all elements
  def translate_and_join(separator = ', ', description = '', options = {})
    self.translate(description, options).join(separator).tml_translated
  end

  # translate array values 
  def translate(description = '', options = {})
    return [] if empty?

    collect do |opt|
      if opt.is_a?(String)
        opt.translate(description, {}, options)
      else  
        opt
      end
    end
  end

  # creates a sentence with tr "and" joiner
  def translate_sentence(description = nil, options = {})
    return '' if empty?
    return first if size == 1

    elements = translate(description, options)

    options[:separator] ||= ', '
    options[:joiner] ||= 'and'

    result = elements[0..-2].join(options[:separator])
    result << ' ' << options[:joiner].translate(description || 'List elements joiner', {}, options) << ' '
    result << elements.last

    result.tml_translated
  end

  def tml_translated
    return self if frozen?
    @tml_translated = true
    self
  end

  def tml_translated?
    @tml_translated
  end

end
