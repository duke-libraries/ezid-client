require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec)

desc "Run the ci build (no integration tests)"
task :ci do
  system "rspec . -t ~deprecated -t ~integration"
end

desc "Run tests of deprecated functionality"
task :deprecated do
  system "rspec . -t deprecated"
end

desc "Run the integration tests"
task :integration do
  system "rspec . -t integration"
end

task default: :spec
