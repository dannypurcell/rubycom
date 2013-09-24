#!/bin/env ruby
require 'trollop'

module Test
  def self.call_command(command, arguments, options)
    "Called: Test.#{command}(#{arguments},#{options})"
  end
end

console_hsh = {
    proc_module: Proc.new{|name, documentation, commands, options|
      Trollop::options do
        banner <<-EOS.gsub(/^ {10}/,'')
          #{documentation}

          Usage: #{name} [options]
          Commands:
            #{commands.each_with_index.map{|(k,v), i| "#{"  "if i>0}#{k} - #{v}"}.join("\n")}
        EOS
        banner "Options:\n" unless options.empty?
        options.each{|option|
          opt(option[:symbol], option[:doc], option[:opts])
        }
        if ARGV.empty?
          puts "No Command Specified"
          educate
        end
        stop_on commands.keys.map{|key|key.to_s}
      end
    },
    proc_command: Proc.new{|name, documentation, arguments, options|
      called_command = ARGV.delete(name)
      execute = (called_command == name)
      puts "Illegal command call. ARGV[0] should be #{name} but was #{called_command}" unless called_command == name
      options = Trollop::options do
        banner <<-EOS.gsub(/^ {10}/,'')
          #{documentation}

          Usage: #{name} [options]
          Arguments:
            #{arguments.each_with_index.map{|(k,v), i| "#{"  "if i>0}#{k} - #{v}"}.join("\n")}
        EOS
        banner "Options:\n" unless options.empty?
        options.each{|option|
          opt(option[:symbol], option[:doc], option[:opts])
        }
        if ARGV.empty? && !arguments.empty?
          execute = false
          puts "Invalid command call for #{name}"
          educate
        end
      end
      puts Test.call_command(called_command, ARGV, options) if execute
    }
}

case ARGV[0]
  when 'delete'
    console_hsh[:proc_command].call(
        "delete",
        "Docs for delete command",
        {
            test_arg: "a test command arg",
            test_second_arg: "a test command second arg"
        },
        [
            {symbol: :test_delete, doc: "A delete test option", opts: {short: "-d", default: false} }
        ]
    )
  when 'copy'
    console_hsh[:proc_command].call(
        "copy",
        "Docs for copy command",
        {
            test_arg: "a test command arg",
            test_second_arg: "a test command second arg"
        },
        [
            {symbol: :test_copy, doc: "A copy test option", opts: {short: "-c", default: 2} }
        ]
    )
  else
    console_hsh[:proc_module].call(
        $0,
        "A test file's top level doc",
        {
            test_command: "a test command",
            test_command_with_args: "a test command with arguments"
        },
        [
            {symbol: :test_global, doc: "A global test option", opts: {short: "-g", default: "some_global"} }
        ]
    )
end
