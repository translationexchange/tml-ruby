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
