#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

Dir["#{File.dirname(__FILE__)}/tasks/**/*.rake"].sort.each { |ext| load ext }

task :default => :spec
