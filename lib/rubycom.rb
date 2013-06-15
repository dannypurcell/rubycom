require "#{File.expand_path(File.dirname(__FILE__))}/rubycom/version.rb"
require 'yaml'
require 'find'
require 'method_source'

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
          usage = self.get_usage(base)
          puts usage
          return usage
        else
          cmd_usage = self.get_command_usage(base, help_topic, arguments[1..-1])
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
      $stderr.puts self.get_summary(base)
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
      raise CLIError, "Invalid Command: #{command}" unless self.get_top_level_commands(base).include? command.to_sym
      if base.included_modules.map { |mod| mod.name.to_sym }.include?(command.to_sym)
        self.run_command(eval(command), arguments[0], arguments[1..-1])
      else
        method = base.public_method(command.to_sym)
        raise CLIError, "No public method found for symbol: #{command.to_sym}" if method.nil?
        param_defs = self.get_param_definitions(method)
        args = self.parse_arguments(param_defs, arguments)
        (arguments.nil? || arguments.empty?) ? method.call : method.call(*method.parameters.map { |arr| args[arr[1]]}.flatten)
      end
    rescue CLIError => e
      $stderr.puts e
      $stderr.puts self.get_command_usage(base, command, arguments)
    end
  end

  # Parses the given arguments and matches them to the given parameters
  #
  # @param [Hash] parameters a Hash representing the parameters to match.
  #         Entries should match :param_name => { type: :req||:opt||:rest,
  #                                               def:(source_definition),
  #                                               default:(default_value || :nil_rubycom_required_param)
  #                                              }
  # @param [Array] arguments an Array of Strings representing the arguments to be parsed
  # @return [Hash] a Hash mapping the defined parameters to their matching argument values
  def self.parse_arguments(parameters={}, arguments=[])
    raise CLIError, 'parameters may not be nil' if parameters.nil?
    raise CLIError, 'arguments may not be nil' if arguments.nil?
    types = parameters.values.group_by { |hsh| hsh[:type] }.map { |type, defs_arr| Hash[type, defs_arr.length] }.reduce(&:merge) || {}
    raise CLIError, "Wrong number of arguments. Expected at least #{types[:req]}, received #{arguments.length}" if arguments.length < (types[:req]||0)
    raise CLIError, "Wrong number of arguments. Expected at most #{(types[:req]||0) + (types[:opt]||0)}, received #{arguments.length}" if types[:rest].nil? && (arguments.length > ((types[:req]||0) + (types[:opt]||0)))

    sorted_args = arguments.map { |arg|
      Rubycom.parse_arg(arg)
    }.group_by { |hsh|
      hsh.keys.first
    }.map { |key, arr|
      (key == :rubycom_non_opt_arg) ? Hash[key, arr.map { |hsh| hsh.values }.flatten] : Hash[key, arr.map { |hsh| hsh.values.first }.reduce(&:merge)]
    }.reduce(&:merge) || {}

    parameters.map { |param_sym, def_hash|
      if def_hash[:type] == :req
        raise CLIError, "No argument available for #{param_sym}" if sorted_args[:rubycom_non_opt_arg].nil? || sorted_args[:rubycom_non_opt_arg].length == 0
        Hash[param_sym, sorted_args[:rubycom_non_opt_arg].shift]
      elsif def_hash[:type] == :opt
        Hash[param_sym, ((sorted_args[param_sym]) ? sorted_args[param_sym] : ((sorted_args[:rubycom_non_opt_arg].shift || parameters[param_sym][:default]) rescue parameters[param_sym][:default]))]
      elsif def_hash[:type] == :rest
        ret = Hash[param_sym, ((sorted_args[param_sym]) ? sorted_args[param_sym] : sorted_args[:rubycom_non_opt_arg])]
        sorted_args[:rubycom_non_opt_arg] = []
        ret
      end
    }.reduce(&:merge)
  end

  # Uses YAML.load to parse the given String
  #
  # @param [String] arg a String representing the argument to be parsed
  # @return [Object] the result of parsing the given arg with YAML.load
  def self.parse_arg(arg)
    return Hash[:rubycom_non_opt_arg, nil] if arg.nil?
    if arg.is_a?(String) && ((arg.match(/^[-]{3,}\w+/) != nil) || ((arg.match(/^[-]{1,}\w+/) == nil) && (arg.match(/^\w+=/) != nil)))
      raise CLIError, "Improper option specification, options must start with one or two dashes. Received: #{arg}"
    elsif arg.is_a?(String) && arg.match(/^(-|--)\w+[=|\s]{1}/) != nil
      k, v = arg.partition(/^(-|--)\w+[=|\s]{1}/).select { |part|
        !part.empty?
      }.each_with_index.map { |part, index|
        index == 0 ? part.chomp('=').gsub(/^--/, '').gsub(/^-/, '').strip.to_sym : (YAML.load(part) rescue "#{part}")
      }
      Hash[k, v]
    else
      Hash[:rubycom_non_opt_arg, (YAML.load("#{arg}") rescue "#{arg}")]
    end
  end

  # Retrieves the summary for each command method in the given Module
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @return [String] the summary for each command method in the given Module
  def self.get_summary(base)
    self.get_top_level_commands(base).each_with_index.map { |sym, index|
      "#{"Commands:\n" if index == 0}" << self.get_command_summary(base, sym, self.get_separator(sym, self.get_longest_command_name(base).length))
    }.reduce(:+) or "No Commands found for #{base}."
  end

  def self.get_separator(sym, spacer_length=0)
    [].unshift(" " * (spacer_length - sym.to_s.length)).join << "  -  "
  end

  # Retrieves the summary for the given command_name
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [String] command_name the command to retrieve usage for
  # @return [String] a summary of the given command_name
  def self.get_command_summary(base, command_name, separator = '  -  ')
    raise CLIError, "Can not get usage for #{command_name} with base: #{base||"nil"}" if base.nil? || !base.respond_to?(:included_modules)
    return 'No command specified.' if command_name.nil? || command_name.length == 0
    if base.included_modules.map { |mod| mod.name.to_sym }.include?(command_name.to_sym)
      begin
      mod_const = Kernel.const_get(command_name.to_sym)
      desc = File.read(mod_const.public_method(mod_const.singleton_methods().first).source_location.first).split(//).reduce(""){|str,c|
        unless str.gsub("\n",'').gsub(/\s+/,'').include?("module#{mod_const}")
          str << c
          end
          str
      }.split("\n").select{|line| line.strip.match(/^#/)}.map{|line| line.strip.gsub(/^#+/,'')}.join("\n")
      rescue
        desc = ""
      end
    else
      raise CLIError, "Invalid command for #{base}, #{command_name}" unless base.public_methods.include?(command_name.to_sym)
      desc = self.get_doc(base.public_method(command_name.to_sym))[:desc].join("\n") rescue ""
    end
    (desc.nil?||desc=='nil'||desc.length==0) ? "#{command_name}\n" : self.get_formatted_summary(command_name, desc, separator)
  end

  def self.get_formatted_summary(command_name, command_description, separator = '  -  ')
    width = 95
    prefix = command_name.to_s.split(//).map { " " }.join + separator.split(//).map { " " }.join
    line_width = width - prefix.length
    description_msg = command_description.gsub(/(.{1,#{line_width}})(?: +|$)\n?|(.{#{line_width}})/, "#{prefix}"+'\1\2'+"\n")
    "#{command_name}#{separator}#{description_msg.lstrip}"
  end

  # Retrieves the usage description for the given Module with a list of command methods
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @return [String] the usage description for the module with a list of command methods
  def self.get_usage(base)
    return '' if base.nil? || !base.respond_to?(:included_modules)
    return '' if self.get_top_level_commands(base).size == 0
    "Usage:\n    #{base} <command> [args]\n\n" << self.get_summary(base)
  end

  # Retrieves the usage description for the given command_name
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [String] command_name the command to retrieve usage for
  # @param [Array] args the remaining args other than the command_name, used of sub-command look-ups
  # @return [String] the detailed usage description for the given command_name
  def self.get_command_usage(base, command_name, args=[])
    raise CLIError, "Can not get usage for #{command_name} with base: #{base||"nil"}" if base.nil? || !base.respond_to?(:included_modules)
    return 'No command specified.' if command_name.nil? || command_name.length == 0
    if base.included_modules.map { |mod| mod.name.to_sym }.include?(command_name.to_sym)
      if args.empty?
        self.get_usage(eval(command_name.to_s))
      else
        self.get_command_usage(eval(command_name.to_s), args[0], args[1..-1])
      end
    else
      raise CLIError, "Invalid command for #{base}, #{command_name}" unless base.public_methods.include?(command_name.to_sym)
      m = base.public_method(command_name.to_sym)
      method_doc = self.get_doc(m)

      msg = "Usage: #{m.name} #{self.get_param_usage(m)}\n"
      msg << "#{"Parameters:"}\n" unless m.parameters.empty?
      msg << "#{method_doc[:param].join("\n    ")}\n" unless method_doc[:param].nil?
      msg << "#{"Returns:"}\n"  unless method_doc[:return].nil?
      msg << "#{method_doc[:return].join("\n    ")}\n" unless method_doc[:return].nil?
      msg
    end
  end

  def self.get_param_usage(method)
    return "" if method.parameters.nil? || method.parameters.empty?
    method.parameters.map { |type, param| {type => param}
    }.group_by { |entry| entry.keys.first
    }.map { |key, val| Hash[key, val.map { |param| param.values.first }]
    }.reduce(&:merge).map { |type, arr|
      if type == :req
        Hash[type, arr.map { |param| " <#{param.to_s}>" }.reduce(:+)]
      elsif type == :opt
        Hash[type, "[#{arr.map { |param| "-#{param}=val" }.join("|")}]"]
      else
        Hash[type, "[&#{arr.join(',')}]"]
      end
    }.reduce(&:merge).values.join(" ")
  end

  # Builds a hash mapping parameter names (as symbols) to their
  # :type (:req,:opt,:rest), :def (source_definition), :default (default_value || :nil_rubycom_required_param)
  # for each parameter defined by the given method.
  #
  # @param [Method] method the Method who's parameter hash should be built
  # @return [Hash] a Hash representing the given Method's parameters
  def self.get_param_definitions(method)
    raise CLIError, 'method must be an instance of the Method class' unless method.class == Method
    method.parameters.map { |param|
      param[1].to_s
    }.map { |param_name|
      {param_name.to_sym => method.source.split("\n").select { |line| line.include?(param_name) }.first}
    }.map { |param_hash|
      param_def = param_hash.flatten[1].gsub(/(def\s+self\.#{method.name.to_s}|def\s+#{method.name.to_s})/, '').lstrip.chomp.chomp(')').reverse.chomp('(').reverse.split(',').map { |param_n| param_n.lstrip }.select { |candidate| candidate.include?(param_hash.flatten[0].to_s) }.first
      Hash[
          param_hash.flatten[0],
          Hash[
              :def, param_def,
              :type, method.parameters.select { |arr| arr[1] == param_hash.flatten[0] }.flatten[0],
              :default, (param_def.include?('=') ? YAML.load(param_def.split('=')[1..-1].join('=')) : :nil_rubycom_required_param)
          ]
      ]
    }.reduce(&:merge) || {}
  end

  # Retrieves the given method's documentation from it's source code.
  #
  # @param [Method] method the Method who's documentation should be retrieved
  # @return [Hash] a Hash representing the given Method's documentation, documentation parsed as follows:
  #                :desc = the first general method comment lines,
  #                :word = each @word comment (i.e.- a line starting with @param will be saved as :param => ["line"])
  def self.get_doc(method)
    method.comment.split("\n").map { |line|
      line.gsub(/#\s*/, '') }.group_by { |doc|
      if doc.match(/^@\w+/).nil?
        :desc
      else
        doc.match(/^@\w+/).to_s.gsub('@', '').to_sym
      end
    }.map { |key, val|
      Hash[key, val.map { |val_line| val_line.gsub(/^@\w+/, '').lstrip }.select { |line| line != '' }]
    }.reduce(&:merge)
  end

  def self.get_longest_command_name(base)
    return '' if base.nil?
    self.get_commands(base, false).map { |_, mod_hash|
      mod_hash[:commands] + mod_hash[:inclusions].flatten }.flatten.max_by(&:size) or ''
  end

  # Retrieves the singleton methods in the given base
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [Boolean] all if true recursively search for included modules' commands, if false return only top level commands.
  # @return [Hash] a Hash of Symbols representing the command methods in the given base and it's included modules (if all=true)
  def self.get_commands(base, all=true)
    return {} if base.nil? || !base.respond_to?(:singleton_methods) || !base.respond_to?(:included_modules)
    {
        base.name.to_sym => {
            commands: base.singleton_methods(true).select { |sym| ![:included, :extended].include?(sym) },
            inclusions: base.included_modules.select { |mod|
              ![:Rubycom].include?(mod.name.to_sym)
            }.map { |mod|
              all ? self.get_commands(mod) : mod.name.to_sym
            }
        }
    }
  end

  def self.get_top_level_commands(base)
    return {} if base.nil? || !base.respond_to?(:singleton_methods) || !base.respond_to?(:included_modules)
    excluded_commands = [:included, :extended]
    excluded_modules = [:Rubycom]
    base.singleton_methods(true).select { |sym| !excluded_commands.include?(sym) } +
        base.included_modules.select { |mod| !excluded_modules.include?(mod.name.to_sym) }.map { |mod| mod.name.to_sym }.flatten
  end

  def self.index_commands(base)
    excluded_commands = [:included, :extended]
    excluded_modules = [:Rubycom]
    Hash[base.singleton_methods(true).select { |sym| !excluded_commands.include?(sym) }.map { |sym|
      [sym, base]
    }].merge(
        base.included_modules.select { |mod| !excluded_modules.include?(mod.name.to_sym) }.map { |mod|
          self.index_commands(mod)
        }.reduce(&:merge) || {}
    )
  end

end
