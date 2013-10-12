module Rubycom
  module PreProcess

    def self.pre_process(inputs)
      inputs == self.check(inputs)
      commands = inputs[:commands].select { |entry| entry.class == Module || entry.class == Method }
      command = commands.last
      command_doc = inputs[:documented_commands].select { |cmd_hsh| cmd_hsh[:command] == command }.first
      inputs[:parsed_command_line][:command_line][:args] = inputs[:parsed_command_line][:command_line][:args].select { |arg|
        !commands.map { |com|
          if com.class == Method;
            com.name.to_s
          else
            com.to_s
          end }.include?(arg)
      }
      filtered_command_line = inputs[:parsed_command_line][:command_line]
      {
          command: command,
          parameters: self.resolve_params(command.parameters, filtered_command_line),
          cli: {
              command_doc: command_doc[:doc][:full_doc],
              command: (command_doc[:command].class == Method)? command_doc[:command].name.to_s : command_doc[:command].to_s
          }.merge(
              if command.class == Module
                {
                    sub_commands: command_doc[:doc][:sub_command_docs]
                }
              elsif command.class == Method
                {
                    options: command_doc[:doc][:parameters],
                    tags: command_doc[:doc][:tags]
                }
              else
                {}
              end
          )
      }
    end

    def self.resolve_params(params, command_line)
      command_line = command_line.clone

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
      }.reduce({}, &:merge).reject{|_,val| val == :rubycom_no_value }
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
      {value: val, remaining: remaining }
    end

    def self.check(inputs)
      required_keys = [:base, :parsed_command_line, :sourced_commands, :documented_commands]
      raise "#{inputs} should have keys #{required_keys}" unless (inputs.keys - required_keys).size >= 0
      inputs
    end

  end
end
