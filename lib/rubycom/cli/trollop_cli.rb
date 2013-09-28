module Rubycom
  module CLI
    module TrollopCLI
      require 'trollop'

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
      def self.module(name, documentation, commands, options, args=ARGV)
        out = StringIO.new()
        opts = Trollop::options(args) {
          banner <<-EOS.gsub(/^ {12}/, '')
            #{documentation}

            Usage: #{name} [options]
            Commands:
              #{commands.each_with_index.map { |(k, v), i| "#{"  " if i>0}#{k} - #{v}" }.join("\n")}
          EOS
          banner "Options:\n" unless options.empty?
          options.each { |option|
            opt(option[:symbol], option[:doc], option[:opts])
          }
          educate(out)
          stop_on commands.map { |k, _| k }
        }
        {
            args: args,
            opts: opts,
            out: out.string
        }
      end

      # Prints command line interface usage in a format useful for representing a ruby method within a module.
      # Parses the given args for the given options. Parsing will stop either when the parser runs out of args.
      # !modifies the args parameter in place
      #
      # @param [String] name the name of the ruby method
      # @param [String] documentation the full method description
      # @param [Hash] parameters a mapping of the method's parameter names to
      # @param [Hash] options the command line options to print/parse
      # @param [Array] args to be parsed
      # @return [Hash] mapping :args to the remaining args, :opts to a hash mapping option names to parsed values,
      # and :out to the command line interface output which can be used as help for the given inputs.
      def self.command(name, documentation, parameters, options, args=ARGV)
        out = StringIO.new()
        opts = Trollop::options(args) {
          banner <<-EOS.gsub(/^ {12}/, '')
            #{documentation}

            Usage: #{name} [options]
            Arguments:
              #{parameters.each_with_index.map { |(k, v), i| "#{"  " if i>0}#{k}#{sep}#{v}" }.join("\n")}
          EOS
          banner "Options:\n" unless options.empty?
          options.each { |option|
            opt(option[:symbol], option[:doc], option[:opts])
          }
          educate(out)
        }
        {
            args: args,
            opts: opts,
            out: out.string
        }
      end

    end
  end
end
