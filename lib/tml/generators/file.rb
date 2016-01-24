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

require 'rubygems'
require 'rubygems/package'
require 'open-uri'
require 'zlib'
require 'fileutils'

class Tml::Generators::File < Tml::Generators::Base

  def execute
    if cache_version == '0'
      log('No releases have been generated yet. Please visit your Dashboard and publish translations.')
    else
      log("Current cache version: #{cache_version}")

      archive_name = "#{cache_version}.tar.gz"
      path = "#{cache_path}/#{archive_name}"
      url = "#{api_client.application.cdn_host}/#{Tml.config.application[:key]}/#{archive_name}"

      log("Downloading cache file: #{url}")
      open(path, 'wb') do |file|
        file << open(url).read
      end

      log('Extracting cache file...')
      version_path = "#{cache_path}/#{cache_version}"
      untar(ungzip(File.new(path)), version_path)
      log("Cache has been stored in #{version_path}")

      File.unlink(path)

      begin
        FileUtils.rm(current_path) if File.exist?(current_path)
        FileUtils.ln_s(cache_version, current_path)
        log('The new cache path has been marked as current')
      rescue
        log('Could not generate current symlink to the cach path. Please indicate the version manually in the Tml initializer.')
      end
    end
  end

end
