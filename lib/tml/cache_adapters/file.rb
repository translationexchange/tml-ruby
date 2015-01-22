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

class Tml::CacheAdapters::File < Tml::Cache

  def self.cache_path
    "#{Tml.config.cache[:path]}/#{Tml.config.cache[:version]}"
  end

  def self.file_path(key)
    File.join(cache_path, "#{key}.json")
  end

  def cache_name
    'file'
  end

  def segmented?
    return true if Tml.config.cache[:segmented].nil?
    Tml.config.cache[:segmented]
  end

  def fetch(key, opts = {})
    info("Fetching key: #{key}")

    path = self.class.file_path(key)

    if File.exists?(path)
      info("Cache hit: #{key}")
      return JSON.parse(File.read(path))
    end

    info("Cache miss: #{key}")

    return nil unless block_given?

    yield
  end

  def store(key, data, opts = {})
    warn('This is a readonly cache')
  end

  def delete(key, opts = {})
    warn('This is a readonly cache')
  end

  def exist?(key, opts = {})
    File.exists?(self.class.file_path(key))
  end

  def clear(opts = {})
    warn('This is a readonly cache')
  end

  def read_only?
    true
  end

end
