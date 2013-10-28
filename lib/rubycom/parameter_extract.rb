module Rubycom

  class RubycomError < StandardError;
  end

  module ParameterExtract

    def self.extract_parameters(command, parsed_command_line, command_doc)
      command, parsed_command_line, command_doc = self.check(command, parsed_command_line, command_doc)
      self.resolve_params(command, parsed_command_line, command_doc)
    end

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
        raise RubycomError, 'Help Requested'
      end

      raise RubycomError, "No command specified." if command.nil?
      raise RubycomError, "No command specified." if command.class == Module
      raise RubycomError, "Unrecognized command." unless [Method, Module].include?(command.class)
      raise "#{parsed_command_line} should be a Hash but was #{parsed_command_line.class}" if parsed_command_line.class != Hash

      raise "command_doc should be a Hash but was #{command_doc.class}" unless command_doc.class == Hash
      raise "command_doc should have key :parameters" unless command_doc.has_key?(:parameters)
      raise "command_doc[:parameters] should be an array but was #{command_doc[:parameters].class}" unless command_doc[:parameters].class == Array
      command_doc[:parameters].each { |param_hsh|
        raise "parameter #{param_hsh} should be a Hash but was #{param_hsh.class}" unless param_hsh.class == Hash
        raise "parameter #{param_hsh} should have key :param_name" unless param_hsh.has_key?(:param_name)
        raise "parameter #{param_hsh} should have key :default" unless param_hsh.has_key?(:default)
      }
      [command, parsed_command_line, command_doc]
    end

    def self.resolve_params(command, command_line, command_doc)
      params = command.parameters
      param_docs = (command_doc[:parameters] || {}).map { |param_hsh|
        if param_hsh[:type] == :rest
          {
              param_hsh[:param_name].reverse.chomp('*').reverse.to_sym => param_hsh.reject { |k, _| k == :param_name }
          }
        else
          {
              param_hsh[:param_name].to_sym => param_hsh.reject { |k, _| k == :param_name }
          }
        end
      }.reduce({}, &:merge)

      command_line = command_line.clone.map { |type, entry|
        {
            type => entry.clone
        }
      }.reduce({}, &:merge)

      command_line[:args] = command_line[:args].reduce([]) { |arr, arg|
        if  arg == command.name.to_s || arr.include?(command.name.to_s)
          arr << arg
        else
          arr
        end
      }
      command_line[:args].shift if command_line[:args].first == command.name.to_s

      first_char_map = params.group_by { |_, sym| sym.to_s[0] }
      param_names = params.map { |_, sym|
        {
            sym => {
                long: sym.to_s,
                short: (first_char_map[sym.to_s[0]].size == 1) ? sym.to_s[0] : sym.to_s
            }
        }
      }.reduce({}, &:merge)

      params.map { |type, sym|
        case type
          when :opt
            extraction = self.extract(param_names[sym][:long], param_names[sym][:short], command_line[:opts], command_line[:flags], command_line[:args])
            command_line[:opts] = extraction[:remaining][:opts] unless extraction[:remaining][:opts].nil?
            command_line[:flags] = extraction[:remaining][:flags] unless extraction[:remaining][:flags].nil?
            command_line[:args] = extraction[:remaining][:args] unless extraction[:remaining][:args].nil?

            if extraction[:value] == :rubycom_no_value
              {sym => param_docs[sym][:default]}
            else
              {
                  sym => extraction[:value]
              }
            end
          when :rest
            args = command_line[:args] || []
            opts = command_line[:opts] || {}
            flags = command_line[:flags] || {}

            rest_arr = {
                sym => if args.empty? && opts.empty? && flags.empty?
                         param_docs[sym][:default]
                       elsif !args.empty? && opts.empty? && flags.empty?
                         args
                       elsif args.empty? && (!opts.empty? || !flags.empty?)
                         flags.merge(opts)[sym].to_a << flags.merge(opts).reject { |k, _| k == sym }
                       else
                         rest = flags.merge(opts)[sym].to_a << flags.merge(opts).reject { |k, _| k == sym }
                         args + rest
                       end
            }

            command_line[:opts] = {} unless command_line[:opts].nil?
            command_line[:flags] = {} unless command_line[:flags].nil?
            command_line[:args] = [] unless command_line[:args].nil?

            rest_arr
          else
            if command_line[:args].size > 0
              {
                  sym => (command_line[:args].shift)
              }
            else
              raise RubycomError, "Missing required argument: #{sym}" if type == :req
              {sym => param_docs[sym][:default]}
            end

        end
      }.reduce({}, &:merge).reject { |_, val| val == :rubycom_no_value }
    end

    def self.extract(long_name, short_name, opts, flags, args)
      options = opts.clone rescue {}
      flags_opts = flags.clone rescue {}
      arguments = args.clone rescue []

      if options.has_key?(long_name)
        val = options.delete(long_name)
      elsif options.has_key?(short_name)
        val = options.delete(short_name)
      elsif flags_opts.has_key?(long_name)
        val = flags_opts.delete(long_name)
      elsif flags_opts.has_key?(short_name)
        val = flags_opts.delete(short_name)
      elsif arguments.size > 0
        val = arguments.shift
      else
        val = :rubycom_no_value
      end

      remaining = {}
      remaining[:opts] = options
      remaining[:flags] = flags_opts
      remaining[:args] = arguments
      {value: val, remaining: remaining}
    end

  end
end
