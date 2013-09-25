module Rubycom
  module CLI
    module TrollopCLI
      def self.module(name, documentation, commands, options)
        Trollop::options do
          banner <<-EOS.gsub(/^ {12}/,'')
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
      end

      def self.command(name, documentation, arguments, options)
        called_command = ARGV.delete(name)
        execute = (called_command == name)
        puts "Illegal command call. ARGV[0] should be #{name} but was #{called_command}" unless called_command == name
        options = Trollop::options do
          banner <<-EOS.gsub(/^ {12}/,'')
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
      end
    end
  end
end
