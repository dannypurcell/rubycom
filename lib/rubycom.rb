require "#{File.dirname(__FILE__)}/rubycom/arguments.rb"
require "#{File.dirname(__FILE__)}/rubycom/cli.rb"
require "#{File.dirname(__FILE__)}/rubycom/singleton_commands.rb"
require "#{File.dirname(__FILE__)}/rubycom/documentation.rb"
require "#{File.dirname(__FILE__)}/rubycom/sources.rb"
require "#{File.dirname(__FILE__)}/rubycom/version.rb"

require 'yaml'

# Upon inclusion in another Module, Rubycom will attempt to call a method in the including module by parsing
# ARGV for a method name and a list of arguments.
# If found Rubycom will call the method specified in ARGV with the parameters parsed from the remaining arguments
# If a Method match can not be made, Rubycom will print help instead by parsing source comments from the including
# module or it's included modules.
module Rubycom
  class RubycomError < StandardError;
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

  # Determines whether the including module was executed by a gem binary
  #
  # @param [String] base_file_path the path to the including module's source file
  def self.is_executed_by_gem?(base_file_path)
    Gem.loaded_specs.map { |k, s|
      {k => {name: "#{s.name}-#{s.version}", executables: s.executables}}
    }.reduce({}, &:merge).map { |k, s|
      base_file_path.include?(s[:name]) && s[:executables].include?(File.basename(base_file_path))
    }.flatten.reduce(&:|)
  end

  ##
  # Looks up the command specified in the first arg and executes with the rest of the args
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [Array] args a String Array representing the command to run followed by arguments to be passed
  def self.run(base, args=[])
    begin
      arguments = args || []
      default_commands = {
          help: "display this message",
          tab_complete: "print a list of possible matches for a given word",
          register_completions: "setup bash tab completion"
      }
      default_options = [
          CLI.opt('help', 'Display documentation', 'h')
      ]
      cli = CLI.module(
          File.basename($0, ".rb"),
          Rubycom::Documentation.module(base.to_s, Rubycom::Sources.module_source(base))[:full_doc],
          Rubycom::Documentation.map_docs(
              Rubycom::Sources.map_sources(base, Rubycom::Sources.get_top_level_commands(base))
          ).merge(default_commands),
          default_options,
          arguments
      )
      command = cli[:args][0]

      raise RubycomError, "Invalid base class invocation: #{base}" if base.nil?
      raise RubycomError, 'No command specified.' if command.nil? || command.length == 0
      case command
        when 'register_completions'
          puts self.register_completions(base)
        when 'tab_complete'
          puts self.tab_complete(base, args, :Rubycom::SingletonCommands)
        when 'help'
          help_topic = cli[:args][1]
          if help_topic == 'register_completions'
            usage = Documentation.get_register_completions_usage(base)
            puts usage
            return usage
          elsif help_topic == 'tab_complete'
            usage = Documentation.get_tab_complete_usage(base)
            puts usage
            return usage
          else
            cmd_usage = self.run_command(base, args, true)
            puts cmd_usage
            return cmd_usage
          end
        else
          help_mode = !cli[:opts][:help].nil?
          output = self.run_command(base, args, help_mode)
          std_output = nil
          std_output = output.to_yaml unless [String, NilClass, TrueClass, FalseClass, Fixnum, Float, Symbol].include?(output.class)
          puts std_output || output
          return output
      end
    rescue RubycomError => e
      $stderr.puts e
      $stderr.puts cli[:out]
    end
  end

  def self.run_steps(base, *args, plugins_options={})
    plugins = self.load_plugins(
        {
            arguments: Rubycom::ArgParse,
            discover: Rubycom::SingletonCommands,
            source: Rubycom::Sources,
            executor: Rubycom::Executor,
            documentation: Rubycom::YardDoc,
            pre_process: Rubycom::PreProcess,
            post_process: Rubycom::PostProcess,
            cli: Rubycom::CLI,
            error: Rubycom::ErrorHandler,
        }.merge(plugins_options)
    )

    parsed_args = plugins[:arguments].parse(args)
    commands = plugins[:discover].discover_commands(base)
    sourced_commands = plugins[:source].source_commands(commands)
    documented_commands = plugins[:documentation].merge_documentation(sourced_commands)
    processed_input = plugins[:pre_process].pre_process(base, parsed_args, documented_commands)
    begin
      command_result = plugins[:executor].execute_command(processed_input)
    rescue RubycomError => e
      cli_output = plugins[:cli].build_cli(processed_input)
      plugins[:error].handle_error(e, cli_output)
    end
    $stdout.puts plugins[:post_process].post_process(command_result)
  end

  def self.load_plugins(plugins=default_plugins)
    plugins.map { |name, plugin|
      {
          name => plugin.is_a?(Module) ? plugin : plugin.to_s.split('::').reduce(Kernel){|mod, next_mod|
            mod.const_get(next_mod.to_s.to_sym)
          }
      }
    }.reduce({}, &:merge)
  end

  # Handles the method call according to the given arguments. If the specified command is a Module then a recursive search
  # is performed until a Method is found in the specified arguments.
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [Array] arguments a String Array representing the remaining arguments
  def self.run_command(base, arguments=[], help_mode=false)
    begin
      mod_cli = CLI.module(
          base.to_s,
          Rubycom::Documentation.module(base.to_s, Rubycom::Sources.module_source(base))[:full_doc],
          Rubycom::Documentation.map_docs(Rubycom::Sources.map_sources(base, Rubycom::Sources.get_top_level_commands(base))),
          {},
          arguments
      )
      command = mod_cli[:args].shift
      puts "in run_command #{base},#{arguments},#{help_mode}: mod_cli = #{mod_cli.to_yaml}"
      if help_mode && (command.nil? || command.length == 0)
        return mod_cli[:out]
      end

      raise RubycomError, 'No command specified.' if command.nil? || command.length == 0
      matched = Sources.get_top_level_commands(base).select { |cmd_sym, _| cmd_sym == command.to_sym }
      raise RubycomError, "Invalid Command: #{command} for #{base}" if matched.nil? || matched.empty?
      raise RubycomError, "Ambiguous command name #{command} for #{base}. Matches: #{matched}" if matched.class == Array && matched.length > 1
      matched = matched.first if matched.class == Array && matched.length == 1

      case matched[command.to_sym][:type]
        when :module
          self.run_command(eval(command), mod_cli[:args], help_mode)
        when :command
          self.call_method(base, command, mod_cli[:args], help_mode)
        else
          raise "CommandError: Unrecognized command type #{matched[command.to_sym][:type]} for #{matched}"
      end
    rescue RubycomError => e
      $stderr.puts e
      $stderr.puts mod_cli[:out]
    end
  end

  # Calls the given command on the given Module after parsing the given Array of arguments
  #
  # @param [Module] base the module wherein the specified command is defined
  # @param [String] command the name of the Method to call
  # @param [Array] arguments a String Array representing the arguments for the given command
  # @return the result of the specified Method call
  def self.call_method(base, command, arguments=[], help_mode=false)
    method = base.public_method(command.to_sym)
    raise RubycomError, "No public method found for symbol: #{command.to_sym}" if method.nil?

    begin
      com_cli = CLI.command(
          method.name,
          Rubycom::Documentation.command(method.name, Rubycom::Sources.method_source(method))[:full_doc],
          {
              taco: {
                  type: :String,
                  doc: "yum",
                  default: "Tacos are delicious!"
              }
          },
          arguments
      )

      if help_mode
        return com_cli[:out]
      end
      puts "in run_command #{base},#{command},#{arguments},#{help_mode}: com_cli = #{com_cli.to_yaml}"
      param_defs = Arguments.get_param_definitions(method)
      args = Arguments.resolve(param_defs, com_cli[:args], com_cli[:opts])
      flatten = false
      params = method.parameters.map { |arr| flatten = true if arr[0]==:rest; args[arr[1]] }
      if flatten
        rest_arr = params.delete_at(-1)
        if rest_arr.respond_to?(:each)
          rest_arr.each { |arg| params << arg }
        else
          params << rest_arr
        end
      end
      (arguments.nil? || arguments.empty?) ? method.call : method.call(*params)
    rescue RubycomError, Rubycom::CLI::CLIError => e
      $stderr.puts e
      $stderr.puts com_cli[:out]
    end
  end

  # Inserts a tab completion into the current user's .bash_profile with a command entry to register the function for
  # the current running ruby file
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @return [String] a message indicating the result of the command
  def self.register_completions(base)
    completion_function = <<-END.gsub(/^ {4}/, '')

    _#{base}_complete() {
      COMPREPLY=()
      local completions="$(ruby #{File.absolute_path($0)} tab_complete ${COMP_WORDS[*]} 2>/dev/null)"
      COMPREPLY=( $(compgen -W "$completions") )
    }
    complete -o bashdefault -o default -o nospace -F _#{base}_complete #{$0.split('/').last}
    END

    already_registered = File.readlines("#{Dir.home}/.bash_profile").map { |line| line.include?("_#{base}_complete()") }.reduce(:|) rescue false
    if already_registered
      "Completion function for #{base} already registered."
    else
      File.open("#{Dir.home}/.bash_profile", 'a+') { |file|
        file.write(completion_function)
      }
      "Registration complete, run 'source #{Dir.home}/.bash_profile' to enable auto-completion."
    end
  end

  # Discovers a list of possible matches to the given arguments
  # Intended for use with bash tab completion
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [Array] arguments a String Array representing the arguments to be matched
  # @param [Symbol]
  # @return [Array] a String Array including the possible matches for the given arguments
  def self.tab_complete(base, arguments, command_plugin)
    plugin = (command_plugin.class == Module)? command_plugin : self.get_plugin(command_plugin)
    arguments = [] if arguments.nil?
    args = (arguments.include?("tab_complete")) ? arguments[2..-1] : arguments
    matches = ['']
    if args.nil? || args.empty?
      matches = plugin.get_top_level_commands(base).map { |sym| sym.to_s }
    elsif args.length == 1
      matches = plugin.get_top_level_commands(base).map { |sym| sym.to_s }.select { |word| !word.match(/^#{args[0]}/).nil? }
      if matches.size == 1 && matches[0] == args[0]
        matches = self.tab_complete(Kernel.const_get(args[0].to_sym), args[1..-1], plugin)
      end
    elsif args.length > 1
      begin
        matches = self.tab_complete(Kernel.const_get(args[0].to_sym), args[1..-1], plugin)
      rescue Exception
        matches = ['']
      end
    end unless base.nil?
    matches = [''] if matches.nil? || matches.include?(args[0])
    matches
  end

end
