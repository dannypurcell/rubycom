module Rubycom
  module ParameterExtract

    # Calls #resolve_params with the given parameters after calling #check to assert the state of the inputs
    #
    # @param [Method] the method whose parameters should be resolved
    # @param [Hash] parsed_command_line :args => array of arguments, :opts => { opt_key => opt_val }, :flags => { flag_key => flag_val }
    # @param [Hash] command_doc :parameters => an array consisting of a hash for method parameter where
    #   :param_name => the param name as a string,
    #   :type => :req|:opt|:rest,
    #   :default => the default value for the param
    # @return [Hash] command.parameters.each => the value for that parameter extracted from command_line or the default in command_doc
    def self.extract_parameters(command, parsed_command_line, command_doc)
      command, parsed_command_line, command_doc = self.check(command, parsed_command_line, command_doc)
      self.resolve_params(command, parsed_command_line, command_doc)
    end

    # Provides upfront checking for this inputs to #extract_parameters and raises a ParameterExtractError if
    # parsed_command_line includes a help argument, option, or flag
    #
    # @param [Method] the method whose parameters should be resolved
    # @param [Hash] command_line :args => array of arguments, :opts => { opt_key => opt_val }, :flags => { flag_key => flag_val }
    # @param [Hash] command_doc :parameters => an array consisting of a hash for method parameter where
    #   :param_name => the param name as a string,
    #   :type => :req|:opt|:rest,
    #   :default => the default value for the param
    # @return [Array] the given parameters if none of the checks raised an error
    def self.check(command, parsed_command_line, command_doc)
      has_help_optional = false
      command.parameters.select { |type, _| type == :opt }.map { |_, name| name.to_s }.each { |param|
        has_help_optional = ['help', 'h'].include?(param)
      } if command.class == Method
      help_opt = !parsed_command_line[:opts].nil? && [
          parsed_command_line[:opts]['help'],
          parsed_command_line[:opts]['h']
      ].include?(true)
      help_flag = !parsed_command_line[:flags].nil? && [
          parsed_command_line[:flags]['help'],
          parsed_command_line[:flags]['h']
      ].include?(true)
      if !has_help_optional && (help_opt || help_flag)
        raise ParameterExtractError, 'Help Requested'
      end

      raise ParameterExtractError, "No command specified." if command.nil?
      raise ParameterExtractError, "No command specified." if command.class == Module
      raise ParameterExtractError, "Unrecognized command." unless [Method, Module].include?(command.class)
      raise "#{parsed_command_line} should be a Hash but was #{parsed_command_line.class}" if parsed_command_line.class != Hash

      raise ArgumentError, "command_doc should be a Hash but was #{command_doc.class}" unless command_doc.class == Hash
      raise ArgumentError, "command_doc should have key :parameters" unless command_doc.has_key?(:parameters)
      raise ArgumentError, "command_doc[:parameters] should be an array but was #{command_doc[:parameters].class}" unless command_doc[:parameters].class == Array
      command_doc[:parameters].each { |param_hsh|
        raise ArgumentError, "parameter #{param_hsh} should be a Hash but was #{param_hsh.class}" unless param_hsh.class == Hash
        raise ArgumentError, "parameter #{param_hsh} should have key :param_name" unless param_hsh.has_key?(:param_name)
        raise ArgumentError, "parameter #{param_hsh} should have key :type" unless param_hsh.has_key?(:type)
        raise ArgumentError, "parameter #{param_hsh} should have key :default" unless param_hsh.has_key?(:default)
      }
      [command, parsed_command_line, command_doc]
    end

    # Matches parameter names in command.parameters to values from command_line or their default values in command_doc
    #
    # @param [Method] the method whose parameters should be resolved
    # @param [Hash] command_line :args => array of arguments, :opts => { opt_key => opt_val }, :flags => { flag_key => flag_val }
    # @param [Hash] command_doc :parameters => an array consisting of a hash for method parameter where
    #   :param_name => the param name as a string,
    #   :type => :req|:opt|:rest,
    #   :default => the default value for the param
    # @return [Hash] command.parameters.each => the value for that parameter extracted from command_line or the default in command_doc
    def self.resolve_params(command, command_line, command_doc)
      raise ArgumentError, "command should be a Method but was #{command.class}" unless command.class == Method
      command_line = command_line.clone.map { |type, entry|
        {type => entry.clone}
      }.reduce({}, &:merge)
      command_line = self.extract_command_args!(command.name.to_s, command_line)
      params = command.parameters
      param_names = self.get_param_names(params)
      raise ArgumentError, "command_doc should have key :parameters but was #{command_doc}" unless command_doc.has_key?(:parameters)
      param_docs = command_doc[:parameters].map { |param_hsh|
        if param_hsh[:type] == :rest
          {param_hsh.fetch(:param_name).reverse.chomp('*').reverse.to_sym => param_hsh.reject { |k, _| k == :param_name }}
        else
          {param_hsh.fetch(:param_name).to_sym => param_hsh.reject { |k, _| k == :param_name }}
        end
      }.reduce({}, &:merge)

      params.map { |type, sym|
        case type
          when :opt
            unless param_docs.has_key?(sym) && param_docs[sym].has_key?(:default)
              raise ArgumentError, "#{sym} should exist in command_doc[:parameters] and have key :default but has values #{param_docs[sym]}"
            end
            self.resolve_opt!(sym, param_names[sym][:long], param_names[sym][:short], param_docs[sym][:default], command_line)
          when :rest
            self.resolve_rest!(sym, param_docs[sym][:default], command_line)
          else
            self.resolve_others!(sym, type, param_docs[sym][:default], command_line)
        end
      }.reduce({}, &:merge).reject { |_, val| val == :rubycom_no_value }
    end

    # Trims command_line[:args] down to the entries which occur after command_name
    #
    # @param [Object] command_name the entry in command_line[:args] which marks the start of the args to be returned
    # @param [Hash] command_line :args => array of arguments
    # @return [Hash] :args => array of arguments including only the entries which occur after the command_name
    def self.extract_command_args!(command_name, command_line)
      raise ArgumentError, "command_name should be a String|Symbol but was #{command_name}" unless [String, Symbol].include?(command_name.class)
      raise ArgumentError, "command_line should be a hash but was #{command_line}" unless command_line.class == Hash
      return command_line if command_line[:args].nil?

      i = command_line[:args].index(command_name.to_s)
      command_line[:args] = (i.nil?) ? [] : command_line[:args][i..-1]
      command_line[:args].shift if command_line[:args].first == command_name.to_s
      command_line
    end

    # Extracts the a value from command_line for the param_name or returns the default with command_line has no values
    #
    # @param [Object] param_name the key in the returned hash
    # @param [Object] default_value the value in the returned hash if no value could be extracted from command_line
    # @param [Hash] command_line :args => array of arguments, :opts => { opt_key => opt_val }, :flags => { flag_key => flag_val }
    # @return [Hash] param_name => extracted_value|default_value
    def self.resolve_opt!(param_name, long_name, short_name, default_value, command_line)
      raise ArgumentError, "command_line should be a hash but was #{command_line}" unless command_line.class == Hash
      extraction = self.extract!(long_name, short_name, command_line[:opts], command_line[:flags], command_line[:args])
      if extraction == :rubycom_no_value
        {param_name => default_value}
      else
        {param_name => extraction}
      end
    end

    # Creates a long and short name for each symbol in the given params
    #
    # @params [Array] params a list of Symbols to create names for
    # @return [Hash] params.each symbol => a Hash where long => string form of symbol and
    # short => the first char in symbol if unique in params or the string form of symbol if not
    def self.get_param_names(params)
      first_char_map = params.group_by { |_, sym| sym.to_s[0] }
      params.map { |_, sym|
        {
            sym => {
                long: sym.to_s,
                short: (first_char_map[sym.to_s[0]].size == 1) ? sym.to_s[0] : sym.to_s
            }
        }
      }.reduce({}, &:merge)
    end

    # Extracts the remaining values from command_line as an Array or returns the default with command_line has no values
    #
    # @param [Object] param_name the key in the returned hash
    # @param [Object] default_value the value in the returned hash if no value could be extracted from command_line
    # @param [Hash] command_line :args => array of arguments, :opts => { opt_key => opt_val }, :flags => { flag_key => flag_val }
    # @return [Array] the rest of the keys/values in command_line
    def self.resolve_rest!(param_name, default_value, command_line)
      args = command_line[:args] || []
      opts = command_line[:opts] || {}
      flags = command_line[:flags] || {}
      # TODO seems like we still can not call out a rest param on the command line, not sure if that is a problem
      rest_arr = {
          param_name => if args.empty? && opts.empty? && flags.empty?
                          default_value
                        elsif !args.empty? && opts.empty? && flags.empty?
                          args
                        elsif args.empty? && (!opts.empty? || !flags.empty?)
                          joined = self.join(flags, opts)
                          keyed = joined[param_name] || []
                          keyed.to_a << joined.reject { |k, _| k == param_name }
                        else
                          joined = self.join(flags, opts)
                          keyed = joined[param_name] || []
                          rest = keyed.to_a << joined.reject { |k, _| k == param_name }
                          args + rest
                        end
      }

      command_line[:opts] = {} unless command_line[:opts].nil?
      command_line[:flags] = {} unless command_line[:flags].nil?
      command_line[:args] = [] unless command_line[:args].nil?

      rest_arr
    end

    # Calls #update on left passing in right and resolving conflicts by combining left and right values in an array
    #
    # @param [Hash] left the base thing to be updated
    # @param [Hash] right the thing whose keys will be added to left and values combined with left on key collisions
    # @return [Hash] left.keys + right.keys where each key => values from left or right or combined in an array if both
    def self.join(left, right)
      left.update(right) { |_, left_val, right_val|
        if left_val.class == Array
          combined = left_val
        else
          combined = [left_val]
        end

        if right_val.class == Array
          right_val.each { |rv|
            combined << rv
          }
        else
          combined << right_val
        end

        combined
      }
    end

    # Extracts a value from the command_line or returns the default_value if the command_line has no values.
    # Raises a ParameterExtractError if the type was :req and no value was found.
    #
    # @param [Object] param_name the key in the returned hash
    # @param [Symbol] type :req if the parameter is required
    # @param [Object] default_value the value in the returned hash if no value could be extracted from command_line
    # @param [Hash] command_line :args => array of arguments
    # @return [Hash] param_name => value extracted for param_name
    def self.resolve_others!(param_name, type, default_value, command_line)
      if command_line[:args].size > 0
        {param_name => (command_line[:args].shift)}
      else
        raise ParameterExtractError, "Missing required argument: #{param_name}" if type == :req
        {param_name => default_value}
      end
    end

    # Searches opts, then flags, then args for a key matching the given long_name or short_name
    # The first matched key will be removed from the set. The valued paired to the matched key will be returned along
    # with a hash containing the remaining args, opts, and flags.
    # !destructively modifies opts, flags, and args by deleting or shifting a matched value out of the Hash/Array
    #
    # @param [Object] long_name the first key to be searched for in each opts, flags, args
    # @param [Object] short_name the key to be searched for if the long_key is not found in the group under search
    # @param [Hash] opts long_key|short_key => option value for that key
    # @param [Hash] flags long_key|short_key => true|false value for that key
    # @param [Array] args if no matching keys for the long or short name exist in either opts or flags and at least one
    # value is left is args then the first value in args will be pulled as the value to return
    # @return [Hash] the extracted value or :rubycom_no_value if a value could not be matched and args was empty
    def self.extract!(long_name, short_name, opts, flags, args)
      opts = {} if opts.nil?
      flags = {} if flags.nil?
      args = [] if args.nil?

      if opts.has_key?(long_name)
        opts.delete(long_name)
      elsif opts.has_key?(short_name)
        opts.delete(short_name)
      elsif flags.has_key?(long_name)
        flags.delete(long_name)
      elsif flags.has_key?(short_name)
        flags.delete(short_name)
      elsif args.size > 0
        args.shift
      else
        :rubycom_no_value
      end
    end

  end
end
