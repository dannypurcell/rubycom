require "bundler/gem_tasks"

task :default => [:test, :doc, :build]

task :test do
  test_files = Dir.glob("**/test/*/test_*.rb")
  test_files.each { |test_case|
    system("ruby #{test_case}")
    raise "Error during test phase" if $?.exitstatus != 0
  }
end

task :doc do
  system("yard")
  raise "Error during doc phase" if $?.exitstatus != 0
end

task :build do
  gem_specs = Dir.glob("**/*.gemspec")
  gem_specs.each { |gem_spec|
    system("gem build #{gem_spec}")
    raise "Error during build phase" if $?.exitstatus != 0
  }
end
