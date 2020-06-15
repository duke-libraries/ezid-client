require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec)

desc "Run the ci build (no integration tests)"
RSpec::Core::RakeTask.new(:ci) do |t|
  t.rspec_opts = "--tag '~deprecated' --tag '~ezid'"
end

desc "Run tests of deprecated functionality"
RSpec::Core::RakeTask.new(:deprecated) do |t|
  t.rspec_opts = "--tag deprecated"
end

desc "Run the integration tests"
RSpec::Core::RakeTask.new(:integration) do |t|
  t.rspec_opts = "--tag ezid"
end

task default: :spec
