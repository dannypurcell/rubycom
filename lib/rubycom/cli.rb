module Rubycom
  module CLI
    load "#{File.dirname(__FILE__)}/cli/helpers.rb"

    class CLIError < StandardError;
    end

    # Prints command line interface usage in a format useful for representing a ruby module.
    # Parses the given args for the given options. Parsing will stop either when the parser encounters
    # a command name or runs out of args.
    # !modifies the args parameter in place
    #
    # @param [String] name the name of the module
    # @param [String] documentation the full module description
    # @param [Hash] commands a mapping of command names to summary documentation for the command
    # @param [Hash] options the command line options to print/parse
    # @param [Array] args to be parsed
    # @return [Hash] mapping :args to the remaining args, :opts to a hash mapping option names to parsed values,
    # and :out to the command line interface output which can be used as help for the given inputs.
    def self.module(name, documentation, commands, options, arguments, plugin=:optparse)
      required_keys = [:args,:opts,:out]
      begin
        result = case plugin
          when :optparse
            load "#{File.dirname(__FILE__)}/cli/optparse_plugin.rb"
            OptparsePlugin.module(name, documentation, commands, options, arguments)
          else
            raise "Cannot build module #{name}: No CLI plugin found for #{plugin}"
        end
        required_keys.each{|sym|
          raise "Result from plugin #{plugin} for module #{name} missing required key #{sym}" unless result.keys.include?(sym)
        }
        result
      rescue => e
        raise CLIError, e, e.backtrace
      end
    end

    # Prints command line interface usage in a format useful for representing a ruby method within a module.
    # Parses the given args for the given options. Parsing will stop either when the parser runs out of args.
    # !modifies the args parameter in place
    #
    # @param [String] name the name of the ruby method
    # @param [String] documentation the full method description
    # @param [Hash] parameters a mapping of the method's parameter names to param documentation
    # @param [Array] args to be parsed
    # @return [Hash] mapping :args to the remaining args, :opts to a hash mapping option names to parsed values,
    # and :out to the command line interface output which can be used as help for the given inputs.
    def self.command(name, documentation, parameters, arguments, plugin=:optparse)
      required_keys = [:args,:opts,:out]
      begin
        result = case plugin
          when :optparse
            load "#{File.dirname(__FILE__)}/cli/optparse_plugin.rb"
            OptparsePlugin.command(name, documentation, parameters, arguments)
          else
            raise "Cannot build command #{name}: No CLI plugin found for #{plugin}"
        end
        required_keys.each{|sym|
          raise "Result from plugin #{plugin} for command #{name} missing required key #{sym}" unless result.keys.include?(sym)
        }
        result
      rescue => e
        raise CLIError, e, e.backtrace
      end
    end

  end
end
