require 'yard'
require 'rake/testtask'

task :default => [:package]

task :clean do
  FileUtils.rm_rf('./doc')
  FileUtils.rm_rf('./.yardoc')
  FileUtils.rm_rf('./pkg')
  FileUtils.rm(Dir.glob('./rubycom-*.gem'))
end

task :bundle do
  system("bundle install")
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*/*_test.rb']
  t.verbose = true
end

YARD::Rake::YardocTask.new

task :package => [:clean, :bundle, :test, :yard] do
  gem_specs = Dir.glob("**/*.gemspec")
  gem_specs.each { |gem_spec|
    system("gem build #{gem_spec}")
    raise "Error during build phase" if $?.exitstatus != 0
  }
end

task :install => :package do
  load "#{File.expand_path(File.dirname(__FILE__))}/lib/rubycom/version.rb"
  system("gem install #{File.expand_path(File.dirname(__FILE__))}/rubycom-#{Rubycom::VERSION}.gem")
end

task :upgrade => :package do
  system("gem uninstall rubycom -a")
  load "#{File.expand_path(File.dirname(__FILE__))}/lib/rubycom/version.rb"
  system("gem install #{File.expand_path(File.dirname(__FILE__))}/rubycom-#{Rubycom::VERSION}.gem")
end

task :version_set, [:version] do |t, args|
  raise "Must provide a version.\n If you called 'rake version_set 1.2.3', try 'rake version_set[1.2.3]'" if args[:version].nil? || args[:version].empty?

  version_file = <<-END.gsub(/^ {4}/, '')
    module Rubycom
      VERSION = "#{args[:version]}"
    end
  END
  puts "Writing version file:\n #{version_file}"
  File.open("#{File.expand_path(File.dirname(__FILE__))}/lib/rubycom/version.rb", 'w+') { |file|
    file.write(version_file)
  }
  file_text = File.read("#{File.expand_path(File.dirname(__FILE__))}/lib/rubycom/version.rb")
  raise "Could not update version file" if file_text != version_file
end

task :release, [:version] => [:version_set, :package] do |t, args|
  system("git clean -f")
  system("git add .")
  system("git commit -m\"Version to #{args[:version]}\"")
  if $?.exitstatus == 0
    system("git tag -a v#{args[:version]} -m\"Version #{args[:version]} Release\"")
    if $?.exitstatus == 0
      system("git push origin master --tags")
      if $?.exitstatus == 0
        load "#{File.expand_path(File.dirname(__FILE__))}/lib/rubycom/version.rb"
        system("gem push #{File.expand_path(File.dirname(__FILE__))}/rubycom-#{Rubycom::VERSION}.gem")
      end
    end
  end
end