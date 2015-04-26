require 'rake/testtask'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task :console do
  exec "irb -r pravangi -I ./lib"
end

task default: :spec

RSpec::Core::RakeTask.new