require "#{File.dirname(__FILE__)}/rubycom/completions.rb"
require "#{File.dirname(__FILE__)}/rubycom/arg_parse.rb"
require "#{File.dirname(__FILE__)}/rubycom/singleton_commands.rb"
require "#{File.dirname(__FILE__)}/rubycom/sources.rb"
require "#{File.dirname(__FILE__)}/rubycom/yard_doc.rb"
require "#{File.dirname(__FILE__)}/rubycom/parameter_extract.rb"
require "#{File.dirname(__FILE__)}/rubycom/executor.rb"
require "#{File.dirname(__FILE__)}/rubycom/output_handler.rb"
require "#{File.dirname(__FILE__)}/rubycom/command_interface.rb"
require "#{File.dirname(__FILE__)}/rubycom/error_handler.rb"

require 'yaml'

# Upon inclusion in another Module, Rubycom will attempt to call a method in the including module by parsing
# ARGV for a method name and a list of arguments.
# If found Rubycom will call the method specified in ARGV with the parameters parsed from the remaining arguments
# If a Method match can not be made, Rubycom will print help instead by parsing code comments from the including
# module.
module Rubycom

  class RubycomError < StandardError
  end
  class ArgParseError < RubycomError;
  end
  class ExecutorError < RubycomError;
  end
  class ParameterExtractError < RubycomError;
  end


  # Determines whether the including module was executed by a gem binary
  #
  # @param [String] base_file_path the path to the including module's source file
  # @return [Boolean] true|false
  def self.is_executed_by_gem?(base_file_path)
    Gem.loaded_specs.map { |k, s|
      {k => {name: "#{s.name}-#{s.version}", executables: s.executables}}
    }.reduce({}, &:merge).map { |_, s|
      base_file_path.include?(s[:name]) && s[:executables].include?(File.basename(base_file_path))
    }.flatten.reduce(&:|)
  end

  # Detects that Rubycom was included in another module and calls Rubycom#run
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  def self.included(base)
    base_file_path = caller.first.gsub(/:\d+:.+/, '')
    if base.class == Module && (base_file_path == $0 || self.is_executed_by_gem?(base_file_path))
      base.module_eval {
        Rubycom.run(base, ARGV)
      }
    end
    nil
  end

  # Main entry point for Rubycom. Uses #run_command! to discover and run commands
  #
  # @param [Module] base this will be used to determine available commands
  # @param [Array] args a String Array representing the command to run followed by arguments to be passed
  # @return [Object] the result of calling #run_command! or a String representing a default help message
  def self.run(base, args=[])
    begin
      raise RubycomError, "base should should not be nil" if base.nil?
      case args[0]
        when 'register_completions'
          puts Rubycom::Completions.register_completions(base)
        when 'tab_complete'
          puts Rubycom::Completions.tab_complete(base, args, Rubycom::SingletonCommands)
        when 'help'
          help_topic = args[1]
          if help_topic == 'register_completions'
            puts "Usage: #{base} register_completions"
          elsif help_topic == 'tab_complete'
            usage = "Usage: #{base} tab_complete <word>\nParameters:\n  [String] word the word or partial word to find matches for"
            puts usage
            return usage
          else
            self.run_command!(base, {}, (args[1..-1] << '-h'))
            $stderr.puts <<-END.gsub(/^ {12}/, '')
            Default Commands:
              help                 - prints this help page
              register_completions - setup bash tab completion
              tab_complete         - print a list of possible matches for a given word
            END
          end
        else
          self.run_command!(base, {}, args)
      end
    rescue RubycomError => e
      $stderr.puts e
    end
  end

  # Calls
  # Uses #load_plugins to reference the modules to be used.
  #
  # @param [Module] base will be used to determine available commands
  # @param [Hash] plugins_options should have the following keys mapped to Modules which will be called
  # :arguments, :discover, :parameters, :executor, :source, :documentation, :output, :interface, :error
  # @param [Array] args a String Array representing the command to run followed by arguments to be passed
  # @return [Object] the result of calling the method selected by :discover module using the args from the :arguments module
  # matched to parameters by the :parameters module
  def self.run_command!(base, plugins_options={}, args=[])
    plugins = self.load_plugins(
        {
            arguments: Rubycom::ArgParse,
            discover: Rubycom::SingletonCommands,
            parameters: Rubycom::ParameterExtract,
            executor: Rubycom::Executor,
            source: Rubycom::Sources,
            documentation: Rubycom::YardDoc,
            output: Rubycom::OutputHandler,
            interface: Rubycom::CommandInterface,
            error: Rubycom::ErrorHandler,
        }.merge(plugins_options)
    )

    parsed_command_line = plugins[:arguments].parse_command_line(args)
    command = plugins[:discover].discover_command(base, parsed_command_line)
    begin
      command_doc = plugins[:documentation].document_command(command, plugins[:source])
      parameters = plugins[:parameters].extract_parameters(command, parsed_command_line, command_doc)
      command_result = plugins[:executor].execute_command(command, parameters)
      plugins[:output].process_output(command_result)
    rescue RubycomError => e
      cli_output = plugins[:interface].build_interface(command, command_doc)
      plugins[:error].handle_error(e, cli_output)
    end
    command_result
  end

  # Maps plugin names to Module references if they are not already such
  #
  # @param [Hash] plugins :plugin_name => Module|String|Symbol
  # @return [Hash] :plugin_name => Module
  def self.load_plugins(plugins={})
    plugins.map { |name, plugin|
      {
          name => plugin.is_a?(Module) ? plugin : plugin.to_s.split('::').reduce(Kernel) { |mod, next_mod|
            mod.const_get(next_mod.to_s.to_sym)
          }
      }
    }.reduce({}, &:merge)
  end

end
