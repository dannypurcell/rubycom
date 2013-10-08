module Rubycom
  module PreProcess
    require 'yaml'

    def self.check(checked_mod, checked_args, checked_commands)
      [checked_mod, checked_args, checked_commands]
    end

    def self.pre_process(checked_mod, checked_args, checked_commands)
      [checked_mod, checked_args, checked_commands]
    end

    # Builds a hash mapping parameter names (as symbols) to their
    # :type (:req,:opt,:rest), :def (source_definition), :default (default_value || :nil_rubycom_required_param)
    # for each parameter defined by the given method.
    #
    # @param [Method] method the Method who's parameter hash should be built
    # @return [Hash] a Hash representing the given Method's parameters
    def get_param_definitions(method)
      raise RubycomError, 'method must be an instance of the Method class' unless method.class == Method
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

    # Matches the given parameters to the given pre-parsed arguments
    #
    # @param [Hash] parameters a Hash representing the parameters to match.
    #         Entries should match :param_name => { type: :req||:opt||:rest,
    #                                               def:(source_definition),
    #                                               default:(default_value || :nil_rubycom_required_param)
    #                                              }
    # @param [Hash] parsed_args a Hash of parsed arguments where the keys are either the name of the optional argument
    #         the value to designated for or :rubycom_non_opt_arg if the argument was not sent for a specified optional parameter
    # @return [Hash] a Hash mapping the defined parameters to their matching argument values
    def merge_params(parameters={}, parsed_args={})
      parameters.map { |param_sym, def_hash|
        if def_hash[:type] == :req
          raise RubycomError, "No argument available for #{param_sym}" if parsed_args[:rubycom_non_opt_arg].nil? || parsed_args[:rubycom_non_opt_arg].length == 0
          Hash[param_sym, parsed_args[:rubycom_non_opt_arg].shift]
        elsif def_hash[:type] == :opt
          if parsed_args[param_sym].nil?
            arg = (parsed_args[:rubycom_non_opt_arg].nil? || parsed_args[:rubycom_non_opt_arg].empty?) ? parameters[param_sym][:default] : parsed_args[:rubycom_non_opt_arg].shift
          else
            arg = parsed_args[param_sym]
          end
          Hash[param_sym, arg]
        elsif def_hash[:type] == :rest
          ret = Hash[param_sym, ((!parsed_args[param_sym].nil?) ? parsed_args[param_sym] : parsed_args[:rubycom_non_opt_arg])]
          parsed_args[:rubycom_non_opt_arg] = []
          ret
        end
      }.reduce(&:merge)
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
    def resolve(parameters={}, arguments=[])
      raise RubycomError, 'parameters may not be nil' if parameters.nil?
      raise RubycomError, 'arguments may not be nil' if arguments.nil?
      parsed_args = self.parse_args(arguments)

      args = parsed_args[:rubycom_non_opt_arg] || []
      options = parsed_args.select { |key, _| key != :rubycom_non_opt_arg } || {}
      parsed_arg_count = args.length + options.length
      types = parameters.values.group_by { |hsh| hsh[:type] }.map { |type, defs_arr| Hash[type, defs_arr.length] }.reduce(&:merge) || {}
      raise RubycomError, "Wrong number of arguments. Expected at least #{types[:req]}, received #{parsed_arg_count}" if parsed_arg_count < (types[:req]||0)
      raise RubycomError, "Wrong number of arguments. Expected at most #{(types[:req]||0) + (types[:opt]||0)}, received #{parsed_arg_count}" if types[:rest].nil? && (parsed_arg_count > ((types[:req]||0) + (types[:opt]||0)))

      self.merge_params(parameters, parsed_args)
    end

  end
end
