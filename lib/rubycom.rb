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
  class RubycomError < StandardError; end


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

  ##
  # Looks up the command specified in the first arg and executes with the rest of the args
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [Array] args a String Array representing the command to run followed by arguments to be passed
  def self.run(base, args=[])
    begin
      arguments = args || []
      default_commands = {
          help: 'display this message',
          tab_complete: 'print a list of possible matches for a given word',
          register_completions: 'setup bash tab completion'
      }
      arguments
      default_commands
      cli = {}
      command = cli[:args][0]

      raise RubycomError, "Invalid base class invocation: #{base}" if base.nil?
      raise RubycomError, 'No command specified.' if command.nil? || command.length == 0
      case command
        when 'register_completions'
          puts self.register_completions(base)
        when 'tab_complete'
          puts self.tab_complete(base, args, Rubycom::SingletonCommands)
        when 'help'
          help_topic = cli[:args][1]
          if help_topic == 'register_completions'
            usage = YardDoc.get_register_completions_usage(base)
            puts usage
            return usage
          elsif help_topic == 'tab_complete'
            usage = YardDoc.get_tab_complete_usage(base)
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

  def self.run_steps(base, plugins_options={}, *args)
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

    parsed_command_line = plugins[:arguments].parse_command_line(args)
    commands = plugins[:discover].discover_commands(base, parsed_command_line)
    sourced_commands = plugins[:source].source_commands(commands)
    documented_commands = plugins[:documentation].document_commands(sourced_commands)
    processed_input = plugins[:pre_process].pre_process(
        {
            base: base,
            parsed_command_line: parsed_command_line,
            commands: commands,
            sourced_commands: sourced_commands,
            documented_commands: documented_commands
        }
    )
    begin
      command_result = plugins[:executor].execute_command(processed_input)
    rescue RubycomError => e
      cli_output = plugins[:cli].build_cli(processed_input)
      plugins[:error].handle_error(e, cli_output)
    end
    $stdout.puts plugins[:post_process].post_process(command_result)
  end

  def self.load_plugins(plugins={})
    plugins.map { |name, plugin|
      {
          name => plugin.is_a?(Module) ? plugin : plugin.to_s.split('::').reduce(Kernel){|mod, next_mod|
            mod.const_get(next_mod.to_s.to_sym)
          }
      }
    }.reduce({}, &:merge)
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
    plugin = (command_plugin.class == Module)? command_plugin : self.load_plugins({discover: command_plugin})
    arguments = [] if arguments.nil?
    args = (arguments.include?('tab_complete')) ? arguments[2..-1] : arguments
    matches = %w()
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
        matches = %w()
      end
    end unless base.nil?
    matches = %w() if matches.nil? || matches.include?(args[0])
    matches
  end

end
