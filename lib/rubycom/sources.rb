module Rubycom
  module Sources
    require 'method_source'

    def self.map_sources(base, commands_hsh)
      commands_hsh.map { |com_sym, hsh|
        case hsh[:type]
          when :module
            {
                com_sym => hsh.merge({source: Rubycom::Sources.module_source(Kernel.const_get(com_sym))})
            }
          when :command
            {
                com_sym => hsh.merge({source: Rubycom::Sources.method_source(base.public_method(com_sym))})
            }
          else
            raise "SourceError: Unrecognized command type #{type} for #{com_sym}"
        end
      }.reduce(&:merge)
    end

    # Searches for the source location of the given module. Since modules can be define in many locations, this method
    # looks up the source location for each of the modules methods and filters to the set of files whose name matches
    # the module's name when converted to the prescribed pattern for files which define modules.
    #
    # @param [Module||String||Symbol] mod the module or name/symbol for the module to be sourced
    # @return [String] a string representing the source of the given module or an empty string if no source file could be located
    # an array of file paths where the modules methods are defined
    def self.module_source(mod)
      raise "module should be #{Module}||#{String}||#{Symbol} but was #{mod.class}" unless [Module, String, Symbol].include?(mod.class)
      mod = Kernel.const_get(mod.to_s.to_sym) if (mod.class == String)||(mod.class == Symbol)
      source_files = mod.methods.map { |sym|
        mod.method(sym).source_location.first rescue nil
      }.compact.select { |file|
        File.basename(file, '.*').gsub('_', '').downcase == mod.to_s.downcase
      }.uniq

      return '' if source_files.empty?
      File.read(source_files.first)
    end

    # Discovers the source code for the given method.
    #
    # @param [Method] method the method to be source
    # @return [String] the source of the specified method
    def self.method_source(method)
      raise "method should be #{Method} but was #{method.class}" unless [Method].include?(method.class)
      method.comment + method.source
    end
  end
end
