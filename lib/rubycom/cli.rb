module Rubycom
  module CLI
    def self.module(plugin=:trollop, opts={})
      case plugin
        when :trollop
          load "#{File.dirname(__FILE__)}/cli/trollop_cli.rb"
          Rubycom::CLI::TrollopCLI.module(opts[:name],opts[:documentation],opts[:commands],opts[:options])
        else
          raise "Cannot run module: No CLI plugin found for #{plugin}"
      end
    end

    def self.command(plugin=:trollop, opts={})
      case plugin
        when :trollop
          load "#{File.dirname(__FILE__)}/cli/trollop_cli.rb"
          Rubycom::CLI::TrollopCLI.command(opts[:name],opts[:documentation],opts[:arguments],opts[:options])
        else
          raise "Cannot run command: No CLI plugin found for #{plugin}"
      end
    end
  end
end
