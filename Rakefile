require "#{File.expand_path(File.dirname(__FILE__))}/lib/rubycom/version.rb"
require 'yard'

task :default => [:package]

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
  system("gem install #{File.expand_path(File.dirname(__FILE__))}/rubycom-#{Rubycom::VERSION}.gem")
end

task :release => :package do
  system("gem push #{File.expand_path(File.dirname(__FILE__))}/rubycom-#{Rubycom::VERSION}.gem")
end