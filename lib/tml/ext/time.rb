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

class Time

  def translate(format = :default, options = {})
    language = Tml.session.target_language

    label = (format.is_a?(String) ? format.clone : Tml.config.default_date_formats[format].clone)
    symbols = label.scan(/(%\w)/).flatten.uniq

    selected_tokens = []
    using_tokens = label.index('{')

    if using_tokens
      selected_tokens = Tml::Tokens::Data.parse(label).collect{ |token| token.name(:parens => true) }
    else
      symbols.each do |symbol|
        token = Tml.config.strftime_symbol_to_token(symbol)
        next unless token
        selected_tokens << token
        label.gsub!(symbol, token)
      end
    end

    tokens = {}
    selected_tokens.each do |token|
      case token
        when '{days}'                 then tokens[:days] = options[:with_leading_zero] ? day.with_leading_zero : day.to_s
        when '{year_days}'            then tokens[:year_days] = options[:with_leading_zero] ? yday.with_leading_zero : yday.to_s
        when '{months}'               then tokens[:months] = options[:with_leading_zero] ? month.with_leading_zero : month.to_s
        when '{week_num}'             then tokens[:week_num] = wday
        when '{week_days}'            then tokens[:week_days] = strftime('%w')
        when '{short_years}'          then tokens[:short_years] = strftime('%y')
        when '{years}'                then tokens[:years] = year
        when '{short_week_day_name}'  then tokens[:short_week_day_name] = language.tr(Tml.config.default_abbr_day_name(wday), 'Short name for a day of a week', {}, options)
        when '{week_day_name}'        then tokens[:week_day_name] = language.tr(Tml.config.default_day_name(wday), 'Day of a week', {}, options)
        when '{short_month_name}'     then tokens[:short_month_name] = language.tr(Tml.config.default_abbr_month_name(month - 1), 'Short month name', {}, options)
        when '{month_name}'           then tokens[:month_name] = language.tr(Tml.config.default_month_name(month - 1), 'Month name', {}, options)
        when '{am_pm}'                then tokens[:am_pm] = language.tr(strftime('%p'), 'Meridian indicator', {}, options)
        when '{full_hours}'           then tokens[:full_hours] = hour
        when '{short_hours}'          then tokens[:short_hours] = strftime('%I')
        when '{trimed_hour}'          then tokens[:trimed_hour] = strftime('%l')
        when '{minutes}'              then tokens[:minutes] = strftime('%M')
        when '{seconds}'              then tokens[:seconds] = strftime('%S')
        when '{since_epoch}'          then tokens[:since_epoch] = strftime('%s')
        when '{day_of_month}'         then tokens[:day_of_month] = strftime('%e')
        else
          ''
      end
    end
  
    language.tr(label, nil, tokens, options)
  end
  alias :tr :translate

  def trl(format = :default, options = {})
    tr(format, options.merge!(:skip_decorations => true))
  end

end
