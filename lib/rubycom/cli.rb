module Rubycom
  module CLI

    def self.module(name, documentation, commands, options, arguments, plugin=:trollop)
      case plugin
        when :trollop
          load "#{File.dirname(__FILE__)}/cli/trollop_cli.rb"
          Rubycom::CLI::TrollopCLI.module(name, documentation, commands, options, arguments)
        else
          raise "Cannot run module: No CLI plugin found for #{plugin}"
      end
    end

    def self.command(name, documentation, parameters, arguments, plugin=:trollop)
      case plugin
        when :trollop
          load "#{File.dirname(__FILE__)}/cli/trollop_cli.rb"
          Rubycom::CLI::TrollopCLI.command(name, documentation, parameters, options, arguments)
        else
          raise "Cannot run command: No CLI plugin found for #{plugin}"
      end
    end

  end
end
