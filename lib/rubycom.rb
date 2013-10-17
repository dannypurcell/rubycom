require "#{File.dirname(__FILE__)}/rubycom/completions.rb"
require "#{File.dirname(__FILE__)}/rubycom/arg_parse.rb"
require "#{File.dirname(__FILE__)}/rubycom/singleton_commands.rb"
require "#{File.dirname(__FILE__)}/rubycom/sources.rb"
require "#{File.dirname(__FILE__)}/rubycom/yard_doc.rb"
require "#{File.dirname(__FILE__)}/rubycom/parameter_extract.rb"
require "#{File.dirname(__FILE__)}/rubycom/executor.rb"
require "#{File.dirname(__FILE__)}/rubycom/sub_process_executor.rb"
require "#{File.dirname(__FILE__)}/rubycom/output_handler.rb"
require "#{File.dirname(__FILE__)}/rubycom/command_interface.rb"
require "#{File.dirname(__FILE__)}/rubycom/error_handler.rb"
require "#{File.dirname(__FILE__)}/rubycom/version.rb"

require 'yaml'

# Upon inclusion in another Module, Rubycom will attempt to call a method in the including module by parsing
# ARGV for a method name and a list of arguments.
# If found Rubycom will call the method specified in ARGV with the parameters parsed from the remaining arguments
# If a Method match can not be made, Rubycom will print help instead by parsing source comments from the including
# module or it's included modules.
module Rubycom
  extend Rubycom::Completions
  class RubycomError < StandardError;
  end


  # Determines whether the including module was executed by a gem binary
  #
  # @param [String] base_file_path the path to the including module's source file
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
  end

  ##
  # Looks up the command specified in the first arg and executes with the rest of the args
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [Array] args a String Array representing the command to run followed by arguments to be passed
  def self.run(base, args=[])
    begin
      raise RubycomError, "base should should not be nil" if base.nil?
      case args[0]
        when 'register_completions'
          puts self.register_completions(base)
        when 'tab_complete'
          puts self.tab_complete(base, args, Rubycom::SingletonCommands)
        when 'help'
          help_topic = args[1]
          if help_topic == 'register_completions'
            usage = YardDoc.get_register_completions_usage(base)
            puts usage
            return usage
          elsif help_topic == 'tab_complete'
            usage = YardDoc.get_tab_complete_usage(base)
            puts usage
            return usage
          else
            self.run_command(base, {}, (args[1..-1] << '-h'))
          end
        else
          self.run_command(base, {}, args)
      end
    rescue RubycomError => e
      $stderr.puts e
    end
  end

  def self.run_command(base, plugins_options={}, *args)
    plugins = self.load_plugins(
        {
            arguments: Rubycom::ArgParse,
            discover: Rubycom::SingletonCommands,
            parameters: Rubycom::ParameterExtract,
            executor: Rubycom::SubProcessExecutor,
            source: Rubycom::Sources,
            documentation: Rubycom::YardDoc,
            output: Rubycom::OutputHandler,
            cli: Rubycom::CommandInterface,
            error: Rubycom::ErrorHandler,
        }.merge(plugins_options)
    )

    parsed_command_line = plugins[:arguments].parse_command_line(args)
    command = plugins[:discover].discover_command(base, parsed_command_line)
    begin
      parameters = plugins[:parameters].extract_parameters(command, parsed_command_line)

      command_result = plugins[:executor].execute_command(command, parameters)
      plugins[:output].process_output(command_result)
    rescue RubycomError => e
      cli_output = plugins[:cli].build_interface(command, plugins[:documentation].document_command(command, plugins[:source]))
      plugins[:error].handle_error(e, cli_output)
    end
  end

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
