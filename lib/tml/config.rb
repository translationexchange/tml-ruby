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

module Tml

  class << self
    attr_accessor :config
  end

  # Initializes default config

  def self.config
    @config ||= Tml::Config.new
  end

  # Allows you to configure Tml
  #
  # Tml.configure do |config|
  #    config.application = {:key => "", :secret => ""}
  #
  # end
  #

  def self.configure
    yield(self.config)
  end

  # Allows you to create a block to perform something on adjusted config settings
  # Once the block exists, the config will be reset back to what it was before:
  #
  #  Tml.with_config_settings do |config|
  #     config.format = :text
  #
  #     Do something....
  #
  #  end
  #

  def self.with_config_settings
    old_config = @config.dup
    yield(@config)
    @config = old_config
  end

  # Acts as a global singleton that holds all Tml configuration
  # The class can be extended with a different implementation, as long as the interface is supported
  class Config
    # Configuration Attributes
    attr_accessor :enabled, :locale, :default_level, :format, :application, :context_rules, :logger, :cache, :default_tokens, :localization
    attr_accessor :auto_init, :source_separator

    # Used by Rails and Sinatra extensions
    attr_accessor :current_locale_method, :current_user_method, :translator_options, :i18n_backend
    attr_accessor :invalidator

    # Used for IRB only
    attr_accessor :submit_missing_keys_realtime

    def initialize
      @enabled = true
      @default_level  = 0
      @format = :html
      @subdomains = false
      @auto_init = true
      @source_separator = '@:@'

      @locale = {
        default:    'en',
        method:     'current_locale',
        subdomain:  false,
        extension:  false
      }

      # if running from IRB, make it default to TRUE
      @submit_missing_keys_realtime = (%w(irb pry).include?($0 || ''))

      @current_locale_method = :current_locale
      @current_user_method = :current_user

      @application = nil

      @translator_options = {
        debug: false,
        debug_format_html: "<span style='font-size:20px;color:red;'>{</span> {$0} <span style='font-size:20px;color:red;'>}</span>",
        debug_format: '{{{{$0}}}}',
        split_sentences: false,
        nodes: {
            ignored:    [],
            scripts:    %w(style script),
            inline:     %w(a span i b img strong s em u sub sup),
            short:      %w(i b),
            splitters:  %w(br hr)
        },
        attributes: {
            labels:     %w(title alt)
        },
        name_mapping: {
            b:    'bold',
            i:    'italic',
            a:    'link',
            img:  'picture'
        },
        data_tokens: {
            special: false,
            numeric: false,
            numeric_name: 'num'
        }
      }

      @context_rules = {
        :number => {
          :variables => {
          }
        },
        :gender => {
          :variables => {
              '@gender' => 'gender',
          }
        },
        :genders => {
          :variables => {
            '@genders' => lambda{|list| list.collect do |u|
                u.is_a?(Hash) ? (u['gender'] || u[:gender]) : u.gender
            end
            },
            '@size' => lambda{ |list| list.size }
          }
        },
        :date => {
          :variables => {
          }
        },
        :time => {
          :variables => {
          }
        },
        :list => {
          :variables => {
            '@count' => lambda{|list| list.size}
          }
        },
      }

      @logger  = {
        :enabled  => false,
        :path     => './log/tml.log',
        :level    => 'debug'
      }

      @cache = {
        :enabled  => false
      }

      @default_tokens = {
        :html => {
          :data => {
            :ndash  =>  '&ndash;',       # –
            :mdash  =>  '&mdash;',       # —
            :iexcl  =>  '&iexcl;',       # ¡
            :iquest =>  '&iquest;',      # ¿
            :quot   =>  '&quot;',        # '
            :ldquo  =>  '&ldquo;',       # “
            :rdquo  =>  '&rdquo;',       # ”
            :lsquo  =>  '&lsquo;',       # ‘
            :rsquo  =>  '&rsquo;',       # ’
            :laquo  =>  '&laquo;',       # «
            :raquo  =>  '&raquo;',       # »
            :nbsp   =>  '&nbsp;',        # space
            :lsaquo =>  '&lsaquo;',      # ‹
            :rsaquo =>  '&rsaquo;',      # ›
            :br     =>  '<br/>',         # line break
            :lbrace =>  '{',
            :rbrace =>  '}',
            :trade  =>  '&trade;',       # TM
          },
          :decoration => {
            :strong =>  '<strong>{$0}</strong>',
            :bold   =>  '<strong>{$0}</strong>',
            :b      =>  '<strong>{$0}</strong>',
            :em     =>  '<em>{$0}</em>',
            :italic =>  '<i>{$0}</i>',
            :i      =>  '<i>{$0}</i>',
            :link   =>  "<a href='{$href}'>{$0}</a>",
            :br     =>  '<br>{$0}',
            :strike =>  '<strike>{$0}</strike>',
            :div    =>  "<div id='{$id}' class='{$class}' style='{$style}'>{$0}</div>",
            :span   =>  "<span id='{$id}' class='{$class}' style='{$style}'>{$0}</span>",
            :h1     =>  '<h1>{$0}</h1>',
            :h2     =>  '<h2>{$0}</h2>',
            :h3     =>  '<h3>{$0}</h3>',
          }
        },
        :text => {
          :data => {
            :ndash  =>  '–',
            :mdash  =>  '-',
            :iexcl  =>  '¡',
            :iquest =>  '¿',
            :quot   =>  "'",
            :ldquo  =>  '“',
            :rdquo  =>  '”',
            :lsquo  =>  '‘',
            :rsquo  =>  '’',
            :laquo  =>  '«',
            :raquo  =>  '»',
            :nbsp   =>  ' ',
            :lsaquo =>  '‹',
            :rsaquo =>  '›',
            :br     =>  '\n',
            :lbrace =>  '{',
            :rbrace =>  '}',
            :trade  =>  '™',
          },
          :decoration => {
            :strong =>  '{$0}',
            :bold   =>  '{$0}',
            :b      =>  '{$0}',
            :em     =>  '{$0}',
            :italic =>  '{$0}',
            :i      =>  '{$0}',
            :link   =>  '{$0}:{$1}',
            :br     =>  '\n{$0}',
            :strike =>  '{$0}',
            :div    =>  '{$0}',
            :span   =>  '{$0}',
            :h1     =>  '{$0}',
            :h2     =>  '{$0}',
            :h3     =>  '{$0}',
          }
        }
      }

      @invalidator ||= {
          enabled: true,
          path: '/tml/upgrade',
          auth: lambda do |request|
            request.params[:access_token] == application[:token]
          end
      }

      @localization = {
        :default_day_names        =>  ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
        :default_abbr_day_names   =>  ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
        :default_month_names      =>  ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
        :default_abbr_month_names =>  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
        :custom_date_formats      =>  {
          :default                => '%m/%d/%Y',            # 07/4/2008
          :short_numeric          => '%m/%d',               # 07/4
          :short_numeric_year     => '%m/%d/%y',            # 07/4/08
          :long_numeric           => '%m/%d/%Y',            # 07/4/2008
          :verbose                => '%A, %B %d, %Y',       # Friday, July  4, 2008
          :monthname              => '%B %d',               # July 4
          :monthname_year         => '%B %d, %Y',           # July 4, 2008
          :monthname_abbr         => '%b %d',               # Jul 4
          :monthname_abbr_year    => '%b %d, %Y',           # Jul 4, 2008
          :date_time              => '%m/%d/%Y at %H:%M',   # 01/03/1010 at 5:30
        },
        :token_mapping => {
          '%a' => '{short_week_day_name}',
          '%A' => '{week_day_name}',
          '%b' => '{short_month_name}',
          '%B' => '{month_name}',
          '%p' => '{am_pm}',
          '%d' => '{days}',
          '%e' => '{day_of_month}',
          '%j' => '{year_days}',
          '%m' => '{months}',
          '%W' => '{week_num}',
          '%w' => '{week_days}',
          '%y' => '{short_years}',
          '%Y' => '{years}',
          '%l' => '{trimed_hour}',
          '%H' => '{full_hours}',
          '%I' => '{short_hours}',
          '%M' => '{minutes}',
          '%S' => '{seconds}',
          '%s' => '{since_epoch}'
        }
      }
    end

    def enabled?
      enabled
    end

    def disabled?
      not enabled?
    end

    def nested_value(hash, key, default_value = nil)
      parts = key.split('.')
      parts.each do |part|
        return default_value unless hash[part.to_sym]
        hash = hash[part.to_sym]
      end
      hash
    end

    def translator_option(key)
      nested_value(self.translator_options, key)
    end

    def cache_enabled?
      cache[:enabled].nil? || Tml.config.cache[:enabled]
    end

    #########################################################
    ## Application
    #########################################################

    #
    #def default_level
    #  return Tml.session.application.default_level if Tml.session.application
    #  @default_level
    #end

    def default_locale
      @locale[:default]
    end

    def default_language
      @default_language ||= begin
        file = File.expand_path(File.join(File.dirname(__FILE__), '..', 'tml', 'languages', "#{Tml.config.default_locale}.json"))
        Tml::Language.new(JSON.parse(File.read(file)))
      end
    end

    def default_application
      @default_application ||= Tml::Application.new(:host => Tml::Api::Client::API_HOST)
    end

    def access_token
      @application[:token] || @application[:access_token] || ''
    end

    #########################################################
    ## Decorations
    #########################################################

    def decorator_class
      return Tml::Decorators::Html if @format == :html
      Tml::Decorators::Default
    end

    def default_token_value(token_name, type = :data, format = :html)
      default_tokens[format.to_sym][type.to_sym][token_name.to_sym]
    end

    def set_default_token(token_name, value, type = :data, format = :html)
      default_tokens[format.to_sym] ||= {}
      default_tokens[format.to_sym][type.to_sym] ||= {}
      default_tokens[format.to_sym][type.to_sym][token_name.to_sym] = value
    end

    #########################################################
    ## Localization
    #########################################################

    def strftime_symbol_to_token(symbol)
      localization[:token_mapping][symbol]
    end

    def default_day_names
      localization[:default_day_names]
    end

    def default_day_name(index)
      "" + default_day_names[index]
    end

    def default_abbr_day_names
      localization[:default_abbr_day_names]
    end

    def default_abbr_day_name(index)
      '' + default_abbr_day_names[index]
    end

    def default_month_names
      localization[:default_month_names]
    end

    def default_month_name(index)
      '' + default_month_names[index]
    end

    def default_abbr_month_names
      localization[:default_abbr_month_names]
    end

    def default_abbr_month_name(index)
      '' + default_abbr_month_names[index]
    end

    def default_date_formats
      localization[:custom_date_formats]
    end

  end
end
