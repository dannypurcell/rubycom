module Rubycom
  module Sources
    require 'method_source'

    # Calls #source_commands and filters to the source string of the first command returned
    #
    # @param [Array] command the commands whose source should be returned
    # @return [String] the source code string if the command was a Module or Method. Returns the command otherwise
    def self.source_command(command)
      self.source_commands([command]).first[:source]
    end

    # Checks commands then calls #map_sources
    #
    # @param [Array] commands the commands whose source should be returned
    # @return [Hash] :command => the command from commands, :source => the source code string if the command was a Module or Method
    def self.source_commands(commands)
      com = self.check(commands)
      self.map_sources(com)
    end

    # Provides upfront checking for this inputs to #source_commands
    def self.check(commands)
      raise ArgumentError, "#{commands} should be an Array but was #{commands.class}" unless commands.class == Array
      commands.each { |cmd|
        raise ArgumentError, "#{cmd} should be a Module, Method, or String but was #{cmd.class}" unless [Module, Method, String].include?(cmd.class)
      }
    end

    # Maps each command in commands to a hash containing the command and the source string for that command.
    # Uses #module_source and #method_source to look up source strings when command is a Module or Method.
    #
    # @param [Array] commands the commands whose source should be returned
    # @return [Hash] :command => the command from commands, :source => the source code string if the command was a Module or Method
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

    # Searches for the source location of the given module. Since modules can be defined in many locations, this method
    # looks up the source location for each of the module's singleton methods and joins the source code for the files in
    # which those methods are defined. If the source file could not be found by this process and $0 matches typical ruby
    # pattern for a file containing the module's definition then the source code for $0 will returned.
    #
    # @param [Module] mod the module to be sourced
    # @return [String] a string representing the source of the given module or an empty string if no source file could be located
    def self.module_source(mod)
      raise ArgumentError, "#{mod} should be #{Module} but was #{mod.class}" unless mod.class == Module
      source_files = mod.singleton_methods(true).select { |sym| ![:included, :extended].include?(sym) }.map { |sym|
        mod.method(sym).source_location.first rescue nil
      }.compact.uniq

      if source_files.empty?
        source_files = (File.basename($0, '.*').gsub('_', '').downcase == mod.to_s.downcase)? [$0] : []
      end

      return '' if source_files.empty?
      source_files.reduce(''){|source_str, next_file|
        source_str << File.read(next_file)
        source_str << "\n" unless source_str.end_with?("\n")
        source_str
      } || ''
    end

    # Discovers the source code for the given method.
    #
    # @param [Method] method the method to be source
    # @return [String] the source of the specified method
    def self.method_source(method)
      raise ArgumentError, "#{method} should be #{Method} but was #{method.class}" unless [Method].include?(method.class)
      method.comment + method.source
    end
  end
end
