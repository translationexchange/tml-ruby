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

class Tml::Generators::File < Tml::Generators::Base

  def cache_path
    @cache_path ||= begin
      path = "#{Tml.config.cache[:path]}/#{cache_version}"
      log("Cache will be stored in #{path}")
      FileUtils.mkdir_p(path)
      FileUtils.chmod(0777, path)
      path
    end
  end

  def file_path(key)
    path = key.split('/')
    if path.count > 1
      filename = path.pop
      path = File.join(cache_path, path)
      FileUtils.mkdir_p(path)
      File.join(path, "#{filename}.json")
    else
      File.join(cache_path, "#{path.first}.json")
    end
  end

  def cache(key, data)
    File.open(file_path(key), 'w') { |file| file.write(JSON.pretty_generate(data)) }
  end

  def execute
    cache_application
    cache_languages
    cache_translations
    generate_symlink
  end

  def cache_translations
    log('Downloading translations...')

    languages.each do |language|
      log("Downloading #{language['english_name']} language...")

      if Tml.config.cache[:segmented]
        api_client.paginate('applications/current/sources') do |source|
          next unless source['source']

          cache_path = Tml::Source.cache_key(language['locale'], source['source'])
          log("Downloading #{source['source']} in #{language['locale']} to #{cache_path}...")

          data = api_client.get("sources/#{source['key']}/translations", {:locale => language['locale'], :original => true, :per_page => 1000})
          cache(cache_path, data)
        end
      else
        cache_path = Tml::Application.translations_cache_key(language['locale'])
        log("Downloading translations in #{language['locale']} to #{cache_path}...")
        data = {}
        api_client.paginate('applications/current/translations', {:locale => language['locale'], :original => true, :per_page => 1000}) do |translations|
          data.merge!(translations)
        end
        cache(cache_path, data)
      end
    end
  end

  def rollback
    folders = Dir["#{Tml.config.cache[:path]}/*"]
    folders.delete_if{|e| e.index('current')}.sort!

    if File.exist?(symlink_path)
      current_dest = File.readlink("#{Tml.config.cache[:path]}/current")
      current_dest = "#{Tml.config.cache[:path]}/#{current_dest}"
    else
      current_dest = 'undefined'
    end

    index = folders.index(current_dest)

    if index == 0
      log('There are no earlier cache versions')
      return
    end

    if index.nil?
      new_version_path = folders[folders.size-1]
    else
      new_version_path = folders[index-1]
    end

    new_version_path = new_version_path.split('/').last

    FileUtils.rm(symlink_path) if File.exist?(symlink_path)
    FileUtils.ln_s(new_version_path, symlink_path)

    log("Cache has been rolled back to version #{new_version_path}.")
  end

  def rollup
    folders = Dir["#{Tml.config.cache[:path]}/*"]
    folders.delete_if{|e| e.index('current')}.sort!

    if File.exist?(symlink_path)
      current_dest = File.readlink("#{Tml.config.cache[:path]}/current")
      current_dest = "#{Tml.config.cache[:path]}/#{current_dest}"
    else
      current_dest = 'undefined'
    end

    index = folders.index(current_dest)

    if index == (folders.size - 1)
      log('You are on the latest version of the cache already. No further versions are available')
      return
    end

    if index.nil?
      new_version_path = folders[0]
    else
      new_version_path = folders[index+1]
    end

    new_version_path = new_version_path.split('/').last

    FileUtils.rm(symlink_path) if File.exist?(symlink_path)
    FileUtils.ln_s(new_version_path, symlink_path)

    log("Cache has been upgraded to version #{new_version_path}.")
  end

end
