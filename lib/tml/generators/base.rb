#--
# Copyright (c) 2015 Translation Exchange Inc. http://translationexchange.com
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

class Tml::Generators::Base

  attr_accessor :started_at, :finished_at

  def log(msg)
    msg = "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}: #{msg}"
    puts msg
    Tml.logger.debug(msg)
  end

  def cache_path
    @cache_path ||= begin
      path = Tml.config.cache[:path]
      path ||= 'config/tml'
      FileUtils.mkdir_p(path)
      FileUtils.chmod(0777, path)
      path
    end
  end

  def current_path
    "#{cache_path}/current"
  end

  def cache_version
    @cache_version ||= api_client.get_cache_version
  end

  def cache(key, data)
    raise Tml::Exception.new('Must be implemented by the subclass')
  end

  def execute
    raise Tml::Exception.new('Must be implemented by the subclass')
  end

  def run
    prepare
    execute
    finalize
  end

  def prepare
    @started_at = Time.now
    Tml.session.init
  end

  def api_client
    Tml.session.application.api_client
  end

  def application
    @application ||= api_client.get('projects/current/definition', {})
  end

  def languages
    application['languages']
  end

  def finalize
    @finished_at = Time.now
    log("Cache generation took #{@finished_at - @started_at} mls.")
    log('Done.')
  end

  def ungzip(tarfile)
    z = Zlib::GzipReader.new(tarfile)
    unzipped = StringIO.new(z.read)
    z.close
    unzipped
  end

  def untar(io, destination)
    Gem::Package::TarReader.new io do |tar|
      tar.each do |tarfile|
        destination_file = File.join destination, tarfile.full_name

        if tarfile.directory?
          FileUtils.mkdir_p destination_file
        else
          destination_directory = File.dirname(destination_file)
          FileUtils.mkdir_p destination_directory unless File.directory?(destination_directory)
          File.open destination_file, "wb" do |f|
            f.print tarfile.read
          end
        end
      end
    end
  end

end
