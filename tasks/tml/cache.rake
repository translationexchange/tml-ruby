require 'json'
require 'tml'

namespace :tml do
  namespace :generate_cache do
    task :file do
      Tml.config.init_application
      g = Tml::Generators::Cache::File.new
      g.run
    end
  end
end
