#!/usr/bin/env ruby
require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubycom.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_composite.rb"

# Test library entry point. Acts as the runnable for UtilTestComposite.rb
module UtilTestComposite
  include Rubycom
end