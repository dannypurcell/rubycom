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

  # Base class for all Rubycom errors
  class RubycomError < StandardError
  end
  # To be thrown in case of an error while parsing arguments
  class ArgParseError < RubycomError;
  end
  # To be thrown in case of an error while executing a method
  class ExecutorError < RubycomError;
  end
  # To be thrown in case of an error while extracting parameters
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

  # Main entry point for Rubycom. Uses #run_command to discover and run commands
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
            self.run_command(base, (args[1..-1] << '-h'))
            $stderr.puts <<-END.gsub(/^ {12}/, '')
            Default Commands:
              help                 - prints this help page
              register_completions - setup bash tab completion
              tab_complete         - print a list of possible matches for a given word
            END
          end
        else
          self.run_command(base, args)
      end
    rescue RubycomError => e
      $stderr.puts e
    end
  end

  # Calls the given process method with the given base, args, and steps.
  #
  # @param [Module] base the Module containing the Method or sub Module to run
  # @param [Array] args a String Array representing the command to run followed by arguments to be passed
  # @param [Hash] steps should have the following keys mapped to Methods or Procs which will be called by the process method
  # :arguments, :discover, :documentation, :source, :parameters, :executor, :output, :interface, :error
  # @param [Method|Proc] process a Method or Proc which calls the step_methods in order to parse args and run a command on base
  # @return [Object] the result of calling the method selected by the :discover method using the args from the :arguments method
  # matched to parameters by the :parameters method
  def self.run_command(base, args=[], steps={}, process=Rubycom.public_method(:process))
    process.call(base, args, steps)
  end

  # Calls the given steps with the required parameters and ordering to locate and call a method on base or one of it's
  # included modules. This method expresses a procedure and calls the methods in steps to execute each step in the procedure.
  # If not overridden in steps, then method called for each step will be determined by the return from #step_methods.
  #
  # @param [Module] base the Module containing the Method or sub Module to run
  # @param [Array] args a String Array representing the command to run followed by arguments to be passed
  # @param [Hash] steps should have the following keys mapped to Methods or Procs which will be called by the process method
  # :arguments, :discover, :documentation, :source, :parameters, :executor, :output, :interface, :error
  # @return [Object] the result of calling the method selected by the :discover method using the args from the :arguments method
  # matched to parameters by the :parameters method
  def self.process(base, args=[], steps={})
    steps = self.step_methods.merge(steps)

    parsed_command_line = steps[:arguments].call(args)
    command = steps[:discover].call(base, parsed_command_line)
    begin
      command_doc = steps[:documentation].call(command, steps[:source])
      parameters = steps[:parameters].call(command, parsed_command_line, command_doc)
      command_result = steps[:executor].call(command, parameters)
      steps[:output].call(command_result)
    rescue RubycomError => e
      cli_output = steps[:interface].call(command, command_doc)
      steps[:error].call(e, cli_output)
    end
    command_result
  end

  # Convenience call for use with #process when the default Rubycom functionality is required.
  #
  # @return [Hash] mapping :arguments, :discover, :documentation, :source, :parameters, :executor, :output, :interface, :error
  # to the default methods which carry out the step referred to by the key.
  def self.step_methods()
    {
        arguments: Rubycom::ArgParse.public_method(:parse_command_line),
        discover: Rubycom::SingletonCommands.public_method(:discover_command),
        documentation: Rubycom::YardDoc.public_method(:document_command),
        source: Rubycom::Sources.public_method(:source_command),
        parameters: Rubycom::ParameterExtract.public_method(:extract_parameters),
        executor: Rubycom::Executor.public_method(:execute_command),
        output: Rubycom::OutputHandler.public_method(:process_output),
        interface: Rubycom::CommandInterface.public_method(:build_interface),
        error: Rubycom::ErrorHandler.public_method(:handle_error)
    }
  end

end
