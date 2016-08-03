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

  class << self
    attr_accessor :postoffice
  end

  def self.postoffice
    @postoffice ||= begin
      po_config = Tml.config.postoffice || {}
      Tml::Postoffice.new(
        key:    po_config[:key],
        token:  po_config[:token],
        host:   po_config[:host]
      )
    end
  end

  class Postoffice < Tml::Base

    PO_HOST = 'https://postoffice.translationexchange.com'
    API_VERSION = 'v1'

    attributes :host, :key, :access_token

    # API host
    def host
      super || PO_HOST
    end

    # API token
    def token
      access_token
    end

    # Postoffice API client
    def deliver(to, template, tokens = {}, options = {})
      if key.blank?
        Tml.logger.error("Failed to deliver #{template} to #{to} - PostOffice has not been configured")
        return
      end

      Tml.logger.debug("Delivering #{template} to #{to}")
      params = {
        client_id: key,
        template: template,
        tokens: tokens,
        to: to,
        via: options[:via],
        from: options[:from],
        locale: options[:locale],
        first_name: options[:first_name],
        last_name: options[:last_name],
        name: options[:name]
      }
      params = Tml::Utils.remove_nils(params)
      api_client.execute_request("#{host}/api/#{API_VERSION}/deliver", params, {:method => :post})
    end

    private

    # Create API client
    def api_client
      @api_client ||= Tml.config.api_client[:class].new(application: self)
    end

  end
end
