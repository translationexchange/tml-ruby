#!/usr/bin/env ruby
require './lib/tml/version'

def run(cmd)
  print '$ ' + cmd + "\n"
  system(cmd)
end

run('git checkout master')
run('git merge develop')
run('git push')

run('bundle exec rspec')
run('gem build tml.gemspec')
run("gem install tml-#{Tml::VERSION}.gem --no-ri --no-rdoc")

if ARGV.include?('release')
  run("git tag #{TmlRails::VERSION}")
  run('git push')
  run("gem push tml-#{Tml::VERSION}.gem")
end

run('git checkout develop')
