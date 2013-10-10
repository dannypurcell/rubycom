module Rubycom
  module Sources
    require 'method_source'

    def self.source_commands(commands)
      com = self.check(commands)
      self.map_sources(com)
    end

    def self.check(commands)
      raise "#{commands} should be an Array but was #{commands.class}" unless commands.class == Array
      commands.each { |cmd|
        raise "#{cmd} should be a Module, Method, or String but was #{cmd.class}" unless [Module, Method, String].include?(cmd.class)
      }
    end

    def self.map_sources(commands)
      commands.map { |cmd|
        {
            command: cmd,
            source: if cmd.class == Module
                      self.module_source(cmd)
                    elsif cmd.class == Method
                      self.method_source(cmd)
                    else
                      cmd
                    end
        }
      }
    end

    # Searches for the source location of the given module. Since modules can be define in many locations, this method
    # looks up the source location for each of the modules methods and filters to the set of files whose name matches
    # the module's name when converted to the prescribed pattern for files which define modules.
    #
    # @param [Module] mod the module to be sourced
    # @return [String] a string representing the source of the given module or an empty string if no source file could be located
    # an array of file paths where the modules methods are defined
    def self.module_source(mod)
      raise "#{mod} should be #{Module} but was #{mod.class}" unless mod.class == Module
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
      raise "#{method} should be #{Method} but was #{method.class}" unless [Method].include?(method.class)
      method.comment + method.source
    end
  end
end
