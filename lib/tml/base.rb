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

class Tml::Base
  attr_reader :attributes

  def initialize(attrs = {})
    @attributes = {}
    update_attributes(attrs)
  end

  def update_attributes(attrs = {})
    attrs.each do |key, value|
      #pp [self.class.name, key, self.class.attributes, self.class.attributes.include?(key.to_sym)]
      next unless self.class.attributes.include?(key.to_sym)
      @attributes[key.to_sym] = value
    end
  end

  def self.attributes(*attrs)
    @attribute_names ||= []
    @attribute_names += attrs.collect{|a| a.to_sym} unless attrs.nil?
    @attribute_names
  end
  def self.belongs_to(*attrs) self.attributes(*attrs); end
  def self.has_many(*attrs) self.attributes(*attrs); end

  def method_missing(meth, *args, &block)
    method_name = meth.to_s
    method_suffix = method_name[-1, 1]
    method_key = method_name.to_sym
    if %w(= ?).include?(method_suffix)
      method_key = method_name[0..-2].to_sym 
    end

    if self.class.attributes.index(method_key)
      if method_suffix == '='
        attributes[method_key] = args.first
        return attributes[method_key]
      end
      return attributes[method_key]
    end

    super
  end      

  def self.hash_value(hash, key, opts = {})
    return nil unless hash.is_a?(Hash)
    return hash[key.to_s] || hash[key.to_sym] if opts[:whole]

    value = hash
    key.to_s.split('.').each do |part|
      return nil unless value.is_a?(Hash)
      value = value[part.to_sym] || value[part.to_s]
    end
    value
  end

  def hash_value(hash, key, opts = {})
    self.class.hash_value(hash, key, opts)
  end

  def to_hash(*attrs)
    if attrs.nil? or attrs.empty?
      # default hashing only includes basic types
      keys = []
      self.class.attributes.each do |key|
        value = attributes[key]
        next if value.kind_of?(Tml::Base) or value.kind_of?(Hash) or value.kind_of?(Array)
        keys << key
      end
    else
      keys = attrs
    end

    hash = {}
    keys.each do |key|
      hash[key] = attributes[key]
    end

    proc = Proc.new { |k, v| v.kind_of?(Hash) ? (v.delete_if(&proc); nil) : v.nil? }
    hash.delete_if(&proc)

    hash    
  end

end
