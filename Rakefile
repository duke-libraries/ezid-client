require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec)

namespace :test do
  desc "Clean up test artifacts (e.g., VCR cassettes)"
  task :clean do
    FileUtils.rm_rf File.join(__dir__, "spec", "cassettes")
  end
end

task default: :spec
