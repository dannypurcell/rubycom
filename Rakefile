require "bundler/gem_tasks"
require 'rake/testtask'
require 'yard'

task :default => [:clean, :test, :yard, :package]

task :clean do
  FileUtils.rm_rf('./doc')
  FileUtils.rm_rf('./.yardoc')
  FileUtils.rm_rf('./pkg')
  FileUtils.rm(Dir.glob('./rubycom-*.gem'))
end

task :test do
  test_files = Dir.glob("**/test/*/test_*.rb")
  test_files.each { |test_case|
    ruby test_case rescue SystemExit
    if $?.exitstatus != 0; raise "Error during test phase\n Test: #{test_case}\n Error: #{$!}\n#{$@}" unless $!.nil? end
  }
end

YARD::Rake::YardocTask.new

task :package => [:clean, :test, :yard] do
  gem_specs = Dir.glob("**/*.gemspec")
  gem_specs.each { |gem_spec|
    system("gem build #{gem_spec}")
    raise "Error during build phase" if $?.exitstatus != 0
  }
end

task :install => :package do
  system "gem install ./rubycom-#{Rubycom::VERSION}"
end

task :release => :package do
  system "gem push ./rubycom-#{Rubycom::VERSION}"
end