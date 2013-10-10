module Rubycom
  module SingletonCommands

    def self.check(base_module, arguments)
      arguments = arguments[:command_line][:args] if arguments.class == Hash && arguments.has_key?(:command_line)
      raise "arguments should be an Array but was #{arguments.class}" unless arguments.class == Array
      arguments.each { |arg|
        raise "#{arg} should be a String but was #{arg.class}" unless arg.class == String
      }
      unless [Module, String, Symbol].include?(base_module.class)
        raise "base_module should be a Module, String, or Symbol but was #{base_module.class}"
      end
      base_module = Kernel.const_get(base_module) if base_module.class == Symbol
      base_module = Kernel.const_get(base_module.to_sym) if base_module.class == String
      [base_module, arguments]
    end

    def self.discover_commands(base_module, arguments)
      mod, args = self.check(base_module, arguments)
      args.reduce([mod]) { |acc, arg|
        if acc.last.class == Method || acc.last.class == String
           acc << arg
        else
          arg_sym = arg.to_s.to_sym
          if self.get_top_level_commands(acc.last)[acc.last.to_s.to_sym][arg_sym] == :method
            acc << acc.last.public_method(arg_sym)
          else
            acc << acc.last.const_get(arg_sym)
          end
        end
      }
    end

    # Discovers the commands specified in the given base without considering the commands contained in sub-modules
    #
    # @param [Module] base the base Module to search
    # @return [Hash] a Hash of Symbols representing the command methods in the given base
    def self.get_top_level_commands(base)
      self.get_commands(base, false)
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
              base.included_modules.select { |mod| ![:Rubycom].include?(mod.name.to_sym) }.map { |mod|
                {
                    mod.to_s.to_sym => (all ? self.get_commands(mod, all)[mod.to_s.to_sym] : :module)
                }
              }.reduce({}, &:merge)
          )
      }
    end

  end
end
