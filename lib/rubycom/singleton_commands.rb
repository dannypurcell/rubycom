module Rubycom
  module SingletonCommands

    def self.check(base_module)
      unless [Module,String,Symbol].include?(base_module.class )
        raise "base_module should be a Module, String, or Symbol but was #{base_module.class}"
      end
      return base_module if base_module.class == Module
      return Kernel.const_get(base_module) if base_module.class == Symbol
      return Kernel.const_get(base_module.to_sym) if base_module.class == String
    end

    def self.discover_commands(base_module)
      self.get_top_level_commands(base_module)
    end

    # Discovers the commands specified in the given base without considering the commands contained in sub-modules
    #
    # @param [Module] base the base Module to search
    # @return [Array] a list of command name symbols which are defined in the given Module
    def self.get_top_level_commands(base)
      return {} if base.nil? || !base.respond_to?(:singleton_methods) || !base.respond_to?(:included_modules)
      {
          base.to_s.to_sym => base.singleton_methods(true).select { |sym| ![:included, :extended].include?(sym) }.map { |sym|
            {
                sym => {
                    type: :command
                }
            }
          }.reduce({}, &:merge).merge(
              base.included_modules.select { |mod| ![:Rubycom].include?(mod.name.to_sym) }.map { |sym|
                {
                    sym.to_s.to_sym => {
                        type: :module
                    }
                }
              }.reduce({}, &:merge)
          )
      }
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
                sym => {
                    type: :command
                }
            }
          }.reduce({},&:merge).merge(
              base.included_modules.select { |mod| ![:Rubycom].include?(mod.name.to_sym) }.map { |sym|
                {
                    sym => {
                        type: :module,
                    }.merge(all ? {commands: self.get_commands(Kernel.const_get(sym.to_s.to_sym), all)} : {})
                }
              }.reduce({}, &:merge) || {}
          )
      }
    end

  end
end
