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
          STDOUT.sync = true
          env = job_hash['env']
          if arguments.delete('-test') || arguments.delete('--test')
            puts "[Test Job #{arguments[0]}]"
            job_hash['steps'].each { |step, step_hash|
              puts "[Step #{step}/#{job_hash.length}] #{step_hash['cmd']}"
            }
          else
            puts "[Job #{arguments[0]}]"
            job_hash['steps'].each { |step, step_hash|
              puts "[Step #{step}/#{job_hash.length}] #{step_hash['cmd']}"
              env.map{|key,val| step_hash['cmd'].gsub!("env[#{key}]","#{((val.class == String)&&(val.match(/\w+/)))? "\"#{val}\"":val}")}
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
    raise CLIError, 'No command specified.' if command.nil? || command.length == 0
    begin
      command_sym = command.to_sym
      valid_commands = self.get_top_level_commands(base)
      raise CLIError, "Invalid Command: #{command}" unless valid_commands.include? command_sym
      if base.included_modules.map { |mod| mod.name.to_sym }.include?(command.to_sym)
        self.run_command(eval(command), arguments[0], arguments[1..-1])
      else
        method = base.public_method(command_sym)
        raise CLIError, "No public method found for symbol: #{command_sym}" if method.nil?
        parameters = self.get_param_definitions(method)
        params_hash = self.parse_arguments(parameters, arguments)
        params = []
        method.parameters.each { |type, name|
          if type == :rest
            if params_hash[name].class == Array
              params_hash[name].each { |arg|
                params << arg
              }
            else
              params << params_hash[name]
            end
          else
            params << params_hash[name]
          end
        }
        if arguments.nil? || arguments.empty?
          output = method.call
        else
          output = method.call(*params)
        end
        output
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
    arguments = (!arguments.nil? && arguments.respond_to?(:each)) ? arguments : []
    args_l = arguments.length
    req_l = 0
    opt_l = 0
    has_rest_param = false
    parameters.each_value { |def_hash|
      req_l += 1 if def_hash[:type] == :req
      opt_l += 1 if def_hash[:type] == :opt
      has_rest_param = true if def_hash[:type] == :rest
      def_hash[:default] = self.parse_arg(def_hash[:default])[:arg] unless def_hash[:default] == :nil_rubycom_required_param
    }
    raise CLIError, "Wrong number of arguments. Expected at least #{req_l}, received #{args_l}" if args_l < req_l
    unless has_rest_param
      raise CLIError, "Wrong number of arguments. Expected at most #{req_l + opt_l}, received #{args_l}" if args_l > (req_l + opt_l)
    end

    args = []
    arguments.each { |arg|
      args << self.parse_arg(arg)
    }

    parsed_args = []
    parsed_options = {}
    args.each { |item|
      key = item.keys.first
      val = item.values.first
      if key == :arg
        parsed_args << val
      else
        parsed_options[key]=val
      end
    }

    result_hash = {}
    parameters.each { |param_name, def_hash|
      if def_hash[:type] == :req
        raise CLIError, "No argument available for #{param_name}" if parsed_args.length == 0
        result_hash[param_name] = parsed_args.shift
      elsif def_hash[:type] == :opt
        result_hash[param_name] = parsed_options[param_name]
        result_hash[param_name] = parsed_args.shift if result_hash[param_name].nil?
        result_hash[param_name] = parameters[param_name][:default] if result_hash[param_name].nil?
      elsif def_hash[:type] == :rest
        if parsed_options[param_name].nil?
          result_hash[param_name] = parsed_args
          parsed_args = []
        else
          result_hash[param_name] = parsed_options[param_name]
        end
      end
    }
    result_hash
  end

  # Uses YAML.load to parse the given String
  #
  # @param [String] arg a String representing the argument to be parsed
  # @return [Object] the result of parsing the given arg with YAML.load
  def self.parse_arg(arg)
    param_name = 'arg'
    arg_val = "#{arg}"
    result = {}
    return result[param_name.to_sym]=nil if arg.nil?
    if arg.is_a? String
      raise CLIError, "Improper option specification, options must start with one or two dashes. Received: #{arg}" if (arg.match(/^[-]{3,}\w+/) != nil)
      if arg.match(/^[-]{1,}\w+/) == nil
        raise CLIError, "Improper option specification, options must start with one or two dashes. Received: #{arg}" if (arg.match(/^\w+=/) != nil)
      else
        if arg.match(/^--/) != nil
          arg = arg.reverse.chomp('--').reverse
        elsif arg.match(/^-/) != nil
          arg = arg.reverse.chomp('-').reverse
        end

        if arg.match(/^\w+=/) != nil
          arg_arr = arg.split('=')
          param_name = arg_arr.shift.strip
          arg_val = arg_arr.join('=').lstrip
        elsif arg.match(/^\w+\s+\S+/) != nil
          arg_arr = arg.split(' ')
          param_name = arg_arr.shift
          arg_val = arg_arr.join(' ')
        end
      end
    end
    begin
      val = YAML.load(arg_val)
    rescue Exception
      val = nil
    end
    if val.nil?
      result[param_name.to_sym] = "#{arg_val}"
    else
      result[param_name.to_sym] = val
    end
    result
  end

  # Retrieves the summary for each command method in the given Module
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @return [String] the summary for each command method in the given Module
  def self.get_summary(base)
    longest_name_length = self.get_longest_command_name(base).length
    self.get_top_level_commands(base).each_with_index.map { |sym, index|
      separator = self.get_separator(sym, longest_name_length)
      if index == 0
        "Commands:\n" << self.get_command_summary(base, sym, separator)
      else
        self.get_command_summary(base, sym, separator)
      end
    }.reduce(:+) or "No Commands found for #{base}."
  end

  def self.get_separator(sym, spacer_length=0)
    cmd_name = sym.to_s
    sep_length = spacer_length - cmd_name.length
    separator = ""
    sep_length.times {
      separator << " "
    }
    separator << "  -  "
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
      desc = "Sub-Module-Command"
    else
      raise CLIError, "Invalid command for #{base}, #{command_name}" unless base.public_methods.include?(command_name.to_sym)
      m = base.public_method(command_name.to_sym)
      method_doc = self.get_doc(m)
      desc = method_doc[:desc].join("\n")
    end
    (desc.nil?||desc=='nil'||desc.length==0) ? "#{command_name}\n" : self.get_formatted_summary(command_name, desc, separator)
  end

  def self.get_formatted_summary(command_name, command_description, separator = '  -  ')
    width = 95
    spacer = ""
    command_name.to_s.split(//).each {
      spacer << " "
    }
    sep_space = ""
    separator.split(//).each {
      sep_space << " "
    }
    prefix = "#{spacer}#{sep_space}"
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

      <<-END.gsub(/^ {6}/, '')
      Usage: #{m.name} #{self.get_param_usage(m)}
      #{"Parameters:" unless m.parameters.empty?}
          #{method_doc[:param].join("\n    ") unless method_doc[:param].nil?}
      Returns:
          #{method_doc[:return].join("\n    ") rescue 'void'}
      END
    end
  end

  def self.get_param_usage(method)
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
    source = method.source
    method_name = method.name.to_s
    source_lines = source.split("\n")
    param_names = method.parameters.map { |param| param[1].to_s }
    param_types = {}
    method.parameters.each { |type, name| param_types[name] = type }
    param_def_lines = {}
    param_names.each { |name| param_def_lines[name] = source_lines.select { |line| line.include?(name) }.first }
    param_definitions = {}
    param_def_lines.each { |name, param_def_line|
      param_candidates = param_def_line.gsub(/(def\s+self\.#{method_name}|def\s+#{method_name})/, '').lstrip.chomp.chomp(')').reverse.chomp('(').reverse
      param_definitions[name.to_sym] = {}
      param_definitions[name.to_sym][:def] = param_candidates.split(',').select { |candidate| candidate.include?(name) }.first
      param_definitions[name.to_sym][:type] = param_types[name.to_sym]
      if param_definitions[name.to_sym][:def].include?('=')
        param_definitions[name.to_sym][:default] = param_definitions[name.to_sym][:def].split('=')[1..-1].join('=')
      else
        param_definitions[name.to_sym][:default] = :nil_rubycom_required_param
      end
    }
    param_definitions
  end

  # Retrieves the given method's documentation from it's source code.
  #
  # @param [Method] method the Method who's documentation should be retrieved
  # @return [Hash] a Hash representing the given Method's documentation, documentation parsed as follows:
  #                :desc = the first general method comment, :params = each @param comment, :return  = each @return comment,
  #                :extended = all other general method comments and unrecognized annotations
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
    excluded_commands = [:included, :extended]
    excluded_modules = [:Rubycom]
    {
        base.name.to_sym => {
            commands: base.singleton_methods(true).select { |sym| !excluded_commands.include?(sym) },
            inclusions: base.included_modules.select { |mod| !excluded_modules.include?(mod.name.to_sym) }.map { |mod|
              if all
                self.get_commands(mod)
              else
                mod.name.to_sym
              end
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
