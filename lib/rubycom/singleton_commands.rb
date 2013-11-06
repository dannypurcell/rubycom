module Rubycom
  module SingletonCommands

    # Uses #discover_commands to look up commands in parsed_command_line, filters the result to the last matched command
    # object
    #
    # @param [Module] base_module the module in which to search for commands
    # @param [Hash] parsed_command_line :args => an array of strings representing the search terms
    # @return [Module|Method] the last matched module or method object
    def self.discover_command(base_module, parsed_command_line)
      self.discover_commands(base_module, parsed_command_line).select { |candidate|
        candidate.class == Module || candidate.class == Method
      }.last
    end

    # Performs a depth only search of included modules starting with the base_module. The first word which matches a
    # singleton method in one of the sub modules will be a Method object in the returned array. All matched sub modules
    # will be Module objects in the returned array. All words occurring after a method match will be returned as they
    # appear in parsed_command_line[:args]
    #
    # @param [Module] base_module the module in which to search for commands
    # @param [Hash] parsed_command_line :args => an array of strings representing the search terms
    # @return [Array] consisting of the matched sub Modules followed by the matched Method followed by the remaining args
    def self.discover_commands(base_module, parsed_command_line)
      base_module, args = self.check(base_module, parsed_command_line)
      args.reduce([base_module]) { |acc, arg|
        if acc.last.class == Method || acc.last.class == String
          acc << arg
        else
          arg_sym = arg.to_s.to_sym
          if self.get_commands(acc.last, false)[acc.last.to_s.to_sym][arg_sym] == :method
            acc << acc.last.public_method(arg_sym)
          else
            acc << acc.last.const_get(arg_sym) rescue (acc << arg)
          end
        end
      }
    end

    # Provides upfront checking for this inputs to #discover_commands
    def self.check(base_module, parsed_command_line)
      raise ArgumentError, 'base_module should not be nil' if base_module.nil?
      raise ArgumentError, 'parsed_command_line should not be nil' if parsed_command_line.nil?
      raise ArgumentError, "parsed_command_line should be a Hash but was #{parsed_command_line.class}" if parsed_command_line.class != Hash
      arguments = parsed_command_line[:args] || []
      raise ArgumentError, "args should be an Array but was #{arguments.class}" unless arguments.class == Array
      unless [Module, String, Symbol].include?(base_module.class)
        raise ArgumentError, "base_module should be a Module, String, or Symbol but was #{base_module.class}"
      end
      base_module = Kernel.const_get(base_module) if base_module.class == Symbol
      base_module = Kernel.const_get(base_module.to_sym) if base_module.class == String
      [base_module, arguments.map { |arg| arg.to_s } ]
    end

    # Retrieves the singleton methods in the given base and included Modules
    #
    # @param [Module] base the module which invoked 'include Rubycom'
    # @param [Boolean] all if true recursively search for included modules' commands, if false return only top level commands
    # @return [Hash] a Hash of Symbols representing the command methods in the given base and it's included modules (if all=true)
    def self.get_commands(base, all=true)
      return {} if base.nil? || !base.respond_to?(:singleton_methods) || !base.respond_to?(:included_modules)
      {
          base.to_s.to_sym => base.singleton_methods(true).select { |sym| ![:included, :extended].include?(sym) }.map { |sym|
            {
                sym => :method
            }
          }.reduce({}, &:merge).merge(
              base.included_modules.select { |mod| mod.name.to_sym != :Rubycom }.map { |mod|
                {
                    mod.to_s.to_sym => (all ? self.get_commands(mod, all)[mod.to_s.to_sym] : :module)
                }
              }.reduce({}, &:merge)
          )
      }
    end

  end
end
