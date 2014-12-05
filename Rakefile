require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec)

desc "Run the ci build (no integration tests)"
task :ci do
  system "rspec ./spec/unit/"
end

task default: :spec
