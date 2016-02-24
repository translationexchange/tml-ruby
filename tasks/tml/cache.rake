require 'json'
require 'tml'

namespace :tml do
  namespace :generate_cache do
    task :file do
      Tml.cache.download
    end
  end
end
