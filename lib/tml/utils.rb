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

require 'yaml'
require 'base64'
require 'openssl'
require 'json'
require 'uri'

module Tml
  class Utils
    def self.normalize_tr_params(label, description, tokens, options)
      return label if label.is_a?(Hash)

      if description.is_a?(Hash)
        return {
          :label        => label,
          :description  => nil,
          :tokens       => description,
          :options      => tokens
        }
      end

      {
        :label        => label,
        :description  => description,
        :tokens       => tokens,
        :options      => options
      }
    end

    def self.guid
      (0..16).to_a.map{|a| rand(16).to_s(16)}.join
    end

    def self.interval_timestamp(interval)
      t = Time.now.to_i
      t - (t % interval.to_i)
    end

    def self.cookie_name(app_key)
      "trex_#{app_key}"
    end

    def self.hash_value(hash, key)
      hash[key.to_s] || hash[key.to_sym]
    end

    def self.load_json(file_path, env = nil)
      json = JSON.parse(File.read(file_path))
      return json if env.nil?
      return yml['defaults'] if env == 'defaults'
      yml['defaults'].rmerge(yml[env] || {})
    end

    def self.load_yaml(file_path, env = nil)
      yaml = YAML.load_file(file_path)
      return yaml if env.nil?
      return yaml['defaults'] if env == 'defaults'
      yaml['defaults'].rmerge(yaml[env] || {})
    end

    def self.decode(payload, secret = nil)
      # payload = URI::decode(payload)
      payload = Base64.decode64(payload)
      data = JSON.parse(payload)
      # TODO: Verify signature
      data
    rescue Exception => ex
      {}
    end

    def self.encode(params, secret = nil)
      # TODO: Add signature
      payload = Base64.encode64(params.to_json)
      # URI::encode(payload)
      payload
    rescue Exception => ex
      ''
    end

    def self.split_sentences(text)
      sentence_regex = /[^.!?\s][^.!?]*(?:[.!?](?![\'"]?\s|$)[^.!?]*)*[.!?]?[\'"]?(?=\s|$)/

      sentences = []
      text.scan(sentence_regex).each do |s|
        sentences << s
      end

      sentences
    end

    def self.browser_accepted_locales(header)
      header.split(/\s*,\s*/).collect do |l|
        l += ';q=1.0' unless l =~ /;q=\d+\.\d+$/
        l.split(';q=')
      end.sort do |x,y|
        unless x.first =~ /^[a-z\-]+$/i
          raise Tml::Exception.new('Not correctly formatted')
        end
        y.last.to_f <=> x.last.to_f
      end.collect do |l|
        l.first.downcase.gsub(/-[a-z]+$/i) { |x| x.upcase }
      end
    rescue
      []
    end

  end
end
