module Rubycom

  class RubycomError < StandardError;
  end

  module ParameterExtract

    def self.extract_parameters(command, parsed_command_line)
      command, parsed_command_line = self.check(command, parsed_command_line)
      self.resolve_params(command, parsed_command_line)
    end

    def self.check(command, parsed_command_line)
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

      [command, parsed_command_line]
    end

    def self.resolve_params(command, command_line)
      params = command.parameters
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
              {sym => :rubycom_no_value}
            else
              {
                  sym => extraction[:value]
              }
            end
          when :rest
            if (command_line[:args] + command_line[:opts].keys + command_line[:flags].keys).empty?
              {sym => :rubycom_no_value}
            else
              rest_arr = {
                  sym => (command_line[:args] + command_line[:opts] + command_line[:flags])
              }

              command_line[:opts] = {} unless command_line[:opts].nil?
              command_line[:flags] = {} unless command_line[:flags].nil?
              command_line[:args] = [] unless command_line[:args].nil?

              rest_arr
            end
          else
            if command_line[:args].size > 0
              {
                  sym => (command_line[:args].shift)
              }
            else
              {sym => :rubycom_no_value}
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
      remaining[:opts] = opts unless opts.nil?
      remaining[:flags] = flags unless flags.nil?
      remaining[:args] = args unless args.nil?
      {value: val, remaining: remaining}
    end

  end
end
