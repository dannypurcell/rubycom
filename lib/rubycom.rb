require "#{File.dirname(__FILE__)}/rubycom/arguments.rb"
require "#{File.dirname(__FILE__)}/rubycom/commands.rb"
require "#{File.dirname(__FILE__)}/rubycom/documentation.rb"
require "#{File.dirname(__FILE__)}/rubycom/version.rb"

require 'yaml'

# Upon inclusion in another Module, Rubycom will attempt to call a method in the including module by parsing
# ARGV for a method name and a list of arguments.
# If found Rubycom will call the method specified in ARGV with the parameters parsed from the remaining arguments
# If a Method match can not be made, Rubycom will print help instead by parsing source comments from the including
# module or it's included modules.
module Rubycom
  class CLIError < StandardError;
  end

  # Detects that Rubycom was included in another module and calls Rubycom#run
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  def self.included(base)
    raise CLIError, 'base must be a module' if base.class != Module
    base_file_path = caller.first.gsub(/:\d+:.+/, '')
    if base_file_path == $0
      base.module_eval {
        Rubycom.run(base, ARGV)
      }
    end
  end

  # Looks up the command specified in the first arg and executes with the rest of the args
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [Array] args a String Array representing the command to run followed by arguments to be passed
  def self.run(base, args=[])
    begin
      raise CLIError, "Invalid base class invocation: #{base}" if base.nil?
      command = args[0] || nil
      arguments = args[1..-1] || []

      if command == 'help'
        help_topic = arguments[0]
        if help_topic.nil?
          usage = Documentation.get_usage(base)
          puts usage
          return usage
        else
          cmd_usage = Documentation.get_command_usage(base, help_topic, arguments[1..-1])
          puts cmd_usage
          return cmd_usage
        end
      elsif command == 'job'
        begin
          raise CLIError, 'No job specified' if arguments[0].nil? || arguments[0].empty?
          job_hash = YAML.load_file(arguments[0])
          job_hash = {} if job_hash.nil?
          STDOUT.sync = true
          if arguments.delete('-test') || arguments.delete('--test')
            puts "[Test Job #{arguments[0]}]"
            job_hash['steps'].each { |step, step_hash|
              step = "[Step: #{step}/#{job_hash['steps'].length}]"
              context = step_hash.select{|key| key!="cmd"}.map{|key,val| "[#{key}: #{val}]"}.join(' ')
              env = job_hash['env'] || {}
              env.map { |key, val| step_hash['cmd'].gsub!("env[#{key}]", "#{((val.class == String)&&(val.match(/\w+/))) ? "\"#{val}\"" : val}") }
              cmd = "[cmd: #{step_hash['cmd']}]"
              puts "#{[step,context,cmd].join(' ')}"
            }
          else
            puts "[Job #{arguments[0]}]"
            job_hash['steps'].each { |step, step_hash|
              step = "[Step: #{step}/#{job_hash['steps'].length}]"
              context = step_hash.select{|key| key!="cmd"}.map{|key,val| "[#{key}: #{val}]"}.join(' ')
              env = job_hash['env'] || {}
              env.map { |key, val| step_hash['cmd'].gsub!("env[#{key}]", "#{((val.class == String)&&(val.match(/\w+/))) ? "\"#{val}\"" : val}") }
              cmd = "[cmd: #{step_hash['cmd']}]"
              puts "#{[step,context,cmd].join(' ')}"
              system(step_hash['cmd'])
            }
          end
        rescue CLIError => e
          $stderr.puts e
        end
      else
        output = self.run_command(base, command, arguments)
        std_output = nil
        std_output = output.to_yaml unless [String, NilClass, TrueClass, FalseClass, Fixnum, Float, Symbol].include?(output.class)
        puts std_output || output
        return output
      end

    rescue CLIError => e
      $stderr.puts e
      $stderr.puts Documentation.get_summary(base)
    end
  end

  # Calls the given Method#name on the given Module after parsing the given Array of arguments
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [String] command the name of the Method to call
  # @param [Array] arguments a String Array representing the arguments for the given command
  def self.run_command(base, command, arguments=[])
    arguments = [] if arguments.nil?
    raise CLIError, 'No command specified.' if command.nil? || command.length == 0
    begin
      raise CLIError, "Invalid Command: #{command}" unless Commands.get_top_level_commands(base).include? command.to_sym
      if base.included_modules.map { |mod| mod.name.to_sym }.include?(command.to_sym)
        self.run_command(eval(command), arguments[0], arguments[1..-1])
      else
        method = base.public_method(command.to_sym)
        raise CLIError, "No public method found for symbol: #{command.to_sym}" if method.nil?
        param_defs = Arguments.get_param_definitions(method)
        args = Arguments.parse_arguments(param_defs, arguments)
        flatten = false
        params = method.parameters.map { |arr| flatten = true if arr[0]==:rest; args[arr[1]]}
        if flatten
          rest_arr = params.delete_at(-1)
          rest_arr.each{|arg| params << arg}
        end
        (arguments.nil? || arguments.empty?) ? method.call : method.call(*params)
      end
    rescue CLIError => e
      $stderr.puts e
      $stderr.puts Documentation.get_command_usage(base, command, arguments)
    end
  end

end
