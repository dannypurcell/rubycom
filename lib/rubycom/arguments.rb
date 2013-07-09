require 'yaml'
require 'method_source'

module Rubycom
  module Arguments

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
      sorted_args = arguments.map { |arg|
        self.parse_arg(arg)
      }.group_by { |hsh|
        hsh.keys.first
      }.map { |key, arr|
        (key == :rubycom_non_opt_arg) ? Hash[key, arr.map { |hsh| hsh.values }.flatten(1)] : Hash[key, arr.map { |hsh| hsh.values.first }.reduce(&:merge)]
      }.reduce(&:merge) || {}

      sorted_arg_count = sorted_args.map { |key, val| val }.flatten(1).length
      types = parameters.values.group_by { |hsh| hsh[:type] }.map { |type, defs_arr| Hash[type, defs_arr.length] }.reduce(&:merge) || {}
      raise CLIError, "Wrong number of arguments. Expected at least #{types[:req]}, received #{sorted_arg_count}" if sorted_arg_count < (types[:req]||0)
      raise CLIError, "Wrong number of arguments. Expected at most #{(types[:req]||0) + (types[:opt]||0)}, received #{sorted_arg_count}" if types[:rest].nil? && (sorted_arg_count > ((types[:req]||0) + (types[:opt]||0)))

      parameters.map { |param_sym, def_hash|
        if def_hash[:type] == :req
          raise CLIError, "No argument available for #{param_sym}" if sorted_args[:rubycom_non_opt_arg].nil? || sorted_args[:rubycom_non_opt_arg].length == 0
          Hash[param_sym, sorted_args[:rubycom_non_opt_arg].shift]
        elsif def_hash[:type] == :opt
          if sorted_args[param_sym].nil?
            arg = (sorted_args[:rubycom_non_opt_arg].nil? || sorted_args[:rubycom_non_opt_arg].empty?) ? parameters[param_sym][:default] : sorted_args[:rubycom_non_opt_arg].shift
          else
            arg = sorted_args[param_sym]
          end
          Hash[param_sym, arg]
        elsif def_hash[:type] == :rest
          ret = Hash[param_sym, ((!sorted_args[param_sym].nil?) ? sorted_args[param_sym] : sorted_args[:rubycom_non_opt_arg])]
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
        begin
          parsed_arg = YAML.load("#{arg}")
        rescue Exception
          parsed_arg = "#{arg}"
        end
        Hash[:rubycom_non_opt_arg, parsed_arg]
      end
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

  end
end