module Rubycom
  module PreProcess

    def self.pre_process(inputs)
      inputs == self.check(inputs)
      command = inputs[:commands].select { |entry| entry.class != String }.last
      command_doc = inputs[:documented_commands].select { |cmd_hsh| cmd_hsh[:command] == command }.first
      filtered_command_line = inputs[:command_line].tap{|cl| cl[:args] = cl[:args].select{|arg|arg.class == String} }
      {
          command: command,
          parameters: self.resolve_params(command.parameters, filtered_command_line),
          cli: {
              banner: command_doc[:full_doc]
          }.merge(
              if command.class == Module
                {
                    commands: command_doc[:sub_command_docs]
                }
              elsif command.class == Method
                {
                    options: command_doc[:parameters],
                    tags: command_doc[:tags]
                }
              else
                {}
              end
          )
      }
    end

    def self.resolve_params(params, command_line)
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
            {
                sym => self.extract_optional(
                    param_names[sym][:long],
                    param_names[sym][:short],
                    command_line[:opts],
                    command_line[:flags],
                    command_line[:args]
                )
            }
          when :rest
            {
                sym => ()
            }
          else
            {
                sym => ()
            }
        end
      }.reduce({}, &:merge)
    end

    def self.extract_optional(long_name, short_name, opts, flags, args)
      if opts.has_key?(long_name)
        opts[long_name]
      elsif opts.has_key?(short_name)
        opts[short_name]
      elsif flags.has_key?(long_name)
        flags[long_name]
      elsif flags.has_key?(short_name)
        flags[short_name]
      else
        args.shift
      end

    end

    def self.check(inputs)
      required_keys = [:base, :parsed_command_line, :sourced_commands, :documented_commands]
      raise "#{inputs} should have keys #{required_keys}" unless (inputs.keys - required_keys).size >= 0
      inputs
    end

  end
end
