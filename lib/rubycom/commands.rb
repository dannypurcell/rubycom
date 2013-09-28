module Rubycom
  module Commands

    # Retrieves the singleton methods in the given base and included Modules
    #
    # @param [Module] base the module which invoked 'include Rubycom'
    # @param [Boolean] all if true recursively search for included modules' commands, if false return only top level commands
    # @return [Hash] a Hash of Symbols representing the command methods in the given base and it's included modules (if all=true)
    def self.get_commands(base, all=true)
      return {} if base.nil? || !base.respond_to?(:singleton_methods) || !base.respond_to?(:included_modules)
      base.singleton_methods(true).select { |sym| ![:included, :extended].include?(sym) }.map { |sym|
        {
            sym => {
                type: :command
            }
        }
      }.reduce({}) { |acc, n| acc.merge(n||{}) || {} }.merge(
          base.included_modules.select { |mod| ![:Rubycom].include?(mod.name.to_sym) }.map { |sym|
            {
                sym => {
                    type: :module,
                }.merge(all ? {commands: self.get_commands(Kernel.const_get(sym.to_s.to_sym), all)} : {})
            }
          }.reduce(&:merge) || {}
      )
    end

    # Discovers the commands specified in the given base without considering the commands contained in sub-modules
    #
    # @param [Module] base the base Module to search
    # @return [Array] a list of command name symbols which are defined in the given Module
    def self.get_top_level_commands(base)
      return {} if base.nil? || !base.respond_to?(:singleton_methods) || !base.respond_to?(:included_modules)
      base.singleton_methods(true).select { |sym| ![:included, :extended].include?(sym) }.map { |sym|
        {
            sym => {
                type: :command
            }
        }
      }.reduce(&:merge).merge(
          base.included_modules.select { |mod| ![:Rubycom].include?(mod.name.to_sym) }.map { |sym|
            {
                sym.to_s.to_sym => {
                    type: :module
                }
            }
          }.reduce(&:merge)
      )
    end

    # Discovers the commands specified in the given base and included Modules
    #
    # @param [Module] base the base Module to search
    # @return [Hash] a set of command name symbols mapped to containing Modules
    def self.index_commands(base)
      excluded_commands = [:included, :extended]
      excluded_modules = [:Rubycom]
      Hash[base.singleton_methods(true).select { |sym| !excluded_commands.include?(sym) }.map { |sym|
        [sym, base]
      }].merge(
          base.included_modules.select { |mod| !excluded_modules.include?(mod.name.to_sym) }.map { |mod|
            self.index_commands(mod)
          }.reduce(&:merge) || {}
      )
    end

    # Looks up the commands which will be available on the given base Module and returns the longest command name
    # Used in arranging the command list format
    #
    # @param [Module] base the base Module to look up
    # @return [String] the longest command name which will show in a list of commands for the given base Module
    def self.get_longest_command_name(base)
      return '' if base.nil?
      self.get_commands(base, false).map { |_, mod_hash|
        mod_hash[:commands] + mod_hash[:inclusions].flatten }.flatten.max_by(&:size) or ''
    end

  end
end
