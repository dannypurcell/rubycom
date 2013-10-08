module Rubycom
  module Executor

    def self.execute_command(processed_input)
      input = self.check(processed_input)
      self.run_command(input[:base], input[:args], input[:help_mode])
    end

    def self.check(processed_input)
      rais "processed_input should be Hash but was #{processed_input.clas}" unless processed_input.class == Hash
      processed_input
    end

    # Handles the method call according to the given arguments. If the specified command is a Module then a recursive search
    # is performed until a Method is found in the specified arguments.
    #
    # @param [Module] base the module which invoked 'include Rubycom'
    # @param [Array] arguments a String Array representing the remaining arguments
    def self.run_command(base, arguments=[], help_mode=false)
      begin
        mod_cli = {}
        command = mod_cli[:args].shift
        puts "in run_command #{base},#{arguments},#{help_mode}: mod_cli = #{mod_cli.to_yaml}"
        if help_mode && (command.nil? || command.length == 0)
          return mod_cli[:out]
        end

        raise RubycomError, 'No command specified.' if command.nil? || command.length == 0
        matched = Sources.get_top_level_commands(base).select { |cmd_sym, _| cmd_sym == command.to_sym }
        raise RubycomError, "Invalid Command: #{command} for #{base}" if matched.nil? || matched.empty?
        raise RubycomError, "Ambiguous command name #{command} for #{base}. Matches: #{matched}" if matched.class == Array && matched.length > 1
        matched = matched.first if matched.class == Array && matched.length == 1

        case matched[command.to_sym][:type]
          when :module
            self.run_command(eval(command), mod_cli[:args], help_mode)
          when :command
            self.call_method(base, command, mod_cli[:args], help_mode)
          else
            raise "CommandError: Unrecognized command type #{matched[command.to_sym][:type]} for #{matched}"
        end
      rescue RubycomError => e
        $stderr.puts e
        $stderr.puts mod_cli[:out]
      end
    end

    # Calls the given command on the given Module after parsing the given Array of arguments
    #
    # @param [Module] base the module wherein the specified command is defined
    # @param [String] command the name of the Method to call
    # @param [Array] arguments a String Array representing the arguments for the given command
    # @return the result of the specified Method call
    def self.call_method(base, command, arguments=[], help_mode=false)
      method = base.public_method(command.to_sym)
      raise RubycomError, "No public method found for symbol: #{command.to_sym}" if method.nil?

      begin
        com_cli = CLI.command(
            method.name,
            Rubycom::YardDoc.command(method.name, Rubycom::Sources.method_source(method))[:full_doc],
            {
                taco: {
                    type: :String,
                    doc: 'yum',
                    default: 'Tacos are delicious!'
                }
            },
            arguments
        )

        if help_mode
          return com_cli[:out]
        end
        puts "in run_command #{base},#{command},#{arguments},#{help_mode}: com_cli = #{com_cli.to_yaml}"
        param_defs = Arguments.get_param_definitions(method)
        args = Arguments.resolve(param_defs, com_cli[:args], com_cli[:opts])
        flatten = false
        params = method.parameters.map { |arr| flatten = true if arr[0]==:rest; args[arr[1]] }
        if flatten
          rest_arr = params.delete_at(-1)
          if rest_arr.respond_to?(:each)
            rest_arr.each { |arg| params << arg }
          else
            params << rest_arr
          end
        end
        (arguments.nil? || arguments.empty?) ? method.call : method.call(*params)
      rescue RubycomError => e
        $stderr.puts e
        $stderr.puts com_cli[:out]
      end
    end

  end
end
