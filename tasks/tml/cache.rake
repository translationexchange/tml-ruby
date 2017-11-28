# encoding: UTF-8
#--
# Copyright (c) 2017 Translation Exchange, Inc
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


require 'tml'

namespace :tml do
  namespace :cache do
    namespace :shared do
      ##########################################
      ## Shared Cache Management
      ##########################################

      desc 'upgrades shared translation cache'
      task :upgrade => :environment do
        Tml.cache.upgrade_version
      end

      desc 'warms up dynamic cache'
      task :warmup => :environment do
        Tml.cache.warmup(ENV['version'], ENV['path'])
      end
    end

    namespace :local do
      ##########################################
      ## Local Cache Management
      ##########################################

      desc 'downloads file cache to local storage'
      task :download => :environment do
        cache_path = ENV['path'] || Tml.cache.default_cache_path
        version = ENV['version']
        pp "Downloading #{version} to #{cache_path}..."
        Tml.cache.download(cache_path, version)
      end

      desc 'rolls back to the previous version'
      task :rollback => :environment do
        raise "Not yet supported"
        # Tml.cache.rollback
      end

      desc 'rolls up to the next version'
      task :rollup => :environment do
        raise "Not yet supported"
        # Tml.cache.rollup
      end
    end
  end
end
