require "#{File.expand_path(File.dirname(__FILE__))}/rubycom/version.rb"
require 'yaml'
require 'method_source'

# Upon inclusion in another Module, Rubycom will attempt to call a method in the including module by parsing
# ARGV and passing for a Method.name and a list of arguments.
# If found Rubycom will call the Method specified by ARGV[0] with the parameters parsed from ARGV[1..-1]
# If a Method match can not be made, Rubycom will print help instead by parsing source documentation from the including
# module.
module Rubycom

  # Detects that Rubycom was included in another module and calls Rubycom#run
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  def self.included(base)
    base.module_eval { Rubycom.run(self, ARGV) }
  end

  # Looks up the command specified in the first arg and executes with the rest of the args
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [Array] args a String Array representing the command to run followed by arguments to be passed
  def self.run(base, args=[])
    begin
      raise "Invalid base class invocation: #{base}" if base.nil?

      command = args[0] || nil
      arguments = args[1..-1] || []

      if command == 'help'
        help_topic = arguments[0]
        if help_topic.nil?
          puts self.get_summary(base)
        else
          puts self.get_command_usage(base, help_topic)
        end
      else
        output = self.run_command(base, command, arguments)
        std_output = nil
        std_output = output.to_yaml unless [String, NilClass, TrueClass, FalseClass, Fixnum, Float, Symbol].include?(output.class)
        puts std_output || output
        return output
      end

    rescue Exception => e
      puts e
      puts self.get_summary(base)
    end
  end

  # Calls the given Method#name on the given Module after parsing the given Array of arguments
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [String] command the name of the Method to call
  # @param [Array] arguments a String Array representing the arguments for the given command
  def self.run_command(base, command, arguments=[])
    raise 'No command specified.' if command.nil? || command.length == 0
    begin
      command_sym = command.to_sym
      valid_commands = self.get_commands(base)
      raise "Invalid Command: #{command}." unless valid_commands.include? command_sym
      method = base.public_method(command_sym)
      raise "No public singleton method found for symbol: #{command_sym}" if method.nil?
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
      output = nil
      if arguments.nil? || arguments.empty?
        output = method.call
      else
        output = method.call(*params)
      end
      output
    rescue Exception => e
      puts e
      puts self.get_command_usage(base, command)
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
    raise "Wrong number of arguments. Expected at least #{req_l}, received #{args_l}" if args_l < req_l
    unless has_rest_param
      raise "Wrong number of arguments. Expected at most #{req_l + opt_l}, received #{args_l}" if args_l > (req_l + opt_l)
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
        raise "No argument available for #{param_name}" if parsed_args.length == 0
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
      raise "Improper option specification, options must start with one or two dashes. Received: #{arg}" if (arg.match(/^[-]{3,}\w+/) != nil)
      if arg.match(/^[-]{1,}\w+/) == nil
        raise "Improper option specification, options must start with one or two dashes. Received: #{arg}" if (arg.match(/^\w+=/) != nil) || (arg.match(/^\w+\s+\S+/) != nil)
      end
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

    val = YAML.load(arg_val) rescue nil
    if val.nil?
      result[param_name.to_sym] = "#{arg_val}"
    else
      result[param_name.to_sym] = val
    end
    result
  end

  # Retrieves the singleton methods in the given base
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @return [Array] an Array of Symbols representing the singleton methods in the given base
  def self.get_commands(base)
    base.singleton_methods(false)
  end

  # Retrieves the summary for each singleton method in the given Module
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @return [String] the summary for each singleton method in the given Module
  def self.get_summary(base)
    return_str = ""
    base_singleton_methods = base.singleton_methods(false)
    return_str << "Commands:\n" unless base_singleton_methods.length == 0
    base_singleton_methods.each { |sym|
      return_str << "  " << self.get_command_summary(base, sym)
    }
    return_str
  end

  # Retrieves the detailed usage description for each singleton method in the given Module
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @return [String] the detailed usage description for each singleton method in the given Module
  def self.get_usage(base)
    return_str = ""
    base_singleton_methods = base.singleton_methods(false)
    return_str << "Commands:\n" unless base_singleton_methods.length == 0
    base_singleton_methods.each { |sym|
      cmd_usage = self.get_command_usage(base, sym)
      return_str << "#{cmd_usage}\n" unless cmd_usage.nil? || cmd_usage.empty?
    }
    return_str
  end

  # Retrieves the summary for the given command_name
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [String] command_name the command to retrieve usage for
  # @return [String] a summary of the given command_name
  def self.get_command_summary(base, command_name)
    return 'No command specified.' if command_name.nil? || command_name.length == 0
    m = base.public_method(command_name.to_sym)
    method_doc = self.get_doc(m)
    desc = method_doc[:desc]
    (desc.nil?||desc=='nil') ? "#{m.name}\n" : "#{m.name} - #{desc}\n"
  end

  # Retrieves the detailed usage description for the given command_name
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  # @param [String] command_name the command to retrieve usage for
  # @return [String] the detailed usage description for the given command_name
  def self.get_command_usage(base, command_name)
    return 'No command specified.' if command_name.nil? || command_name.length == 0
    m = base.public_method(command_name.to_sym)
    optional_params = []
    required_params = []
    method_params = m.parameters || []
    method_params.each { |type, sym|
      if (type == :opt) || (type == 'opt')
        optional_params << sym
      else
        required_params << sym
      end
    }
    method_doc = self.get_doc(m)
    msg = "Command: #{m.name}\n"
    msg << "    Usage: #{m.name}"
    required_params.each { |param|
      msg << " #{param}"
    }
    msg << "\n" if (required_params.length != 0) && (optional_params.length == 0)
    msg << ' [' unless optional_params.length == 0
    optional_params.each_with_index { |option, index|
      if index == 0
        msg << "-#{option}=val"
      else
        msg << "|-#{option}=val"
      end
    }
    msg << "]\n" unless optional_params.length == 0
    msg << "    Parameters:\n" unless (required_params.length == 0) && (optional_params.length == 0)
    if method_doc[:params].respond_to?(:each)
      method_doc[:params].each { |param_doc|
        msg << "        #{param_doc.gsub('[', '').gsub(']', ' -')}\n"
      }
    else
      msg << "\n"
    end
    msg << "    Returns:\n"
    if method_doc[:return].respond_to?(:each)
      method_doc[:return].each { |return_doc|
        msg << "        #{return_doc}\n"
      }
    else
      msg << "        #{method_doc[:return]}\n" unless method_doc[:return].nil? || (method_doc[:return].length == 0)
    end
    msg
  end

  # Builds a hash mapping parameter names (as symbols) to their
  # :type (:req,:opt,:rest), :def (source_definition), :default (default_value || :nil_rubycom_required_param)
  # for each parameter defined by the given method.
  #
  # @param [Method] method the Method who's parameter hash should be built
  # @return [Hash] a Hash representing the given Method's parameters
  def self.get_param_definitions(method)
    raise 'method must be an instance of the Method class' unless method.class == Method
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
    doc_str = method.comment || ''
    doc_hash = {}
    doc_str.split("\n").map { |line| line.gsub(/#\s*/, '') }.each { |doc_line|
      if doc_line.match(/^(@param)/)
        param_doc = doc_line.gsub('@param ', '')
        params = doc_hash[:params]
        if params.nil? || params.length == 0
          params = [param_doc]
        else
          params << param_doc
        end
        doc_hash[:params] = params
      elsif doc_line.match(/^(@return)/)
        if doc_hash[:return].nil?
          doc_hash[:return] = doc_line.gsub('@return ', '')
        else
          doc_hash[:return] = [doc_hash[:return]]
          doc_hash[:return] << doc_line.gsub('@return ', '')
        end
      elsif doc_line.match(/^(@.+\s+)$/) == nil
        if doc_hash[:desc].nil?
          doc_hash[:desc] = doc_line unless doc_line.lstrip.length==0
        else
          doc_hash[:desc] << doc_line unless doc_line.lstrip.length==0
        end
      else
        if doc_hash[:extended].nil?
          doc_hash[:extended] = doc_line
        else
          doc_hash[:extended] << doc_line
        end
      end
    }
    if doc_hash[:return].nil?
      doc_hash[:return] = 'void'
    end
    doc_hash
  end

end
