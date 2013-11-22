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
        raise ArgumentError, "#{cmd} should be a Module, Method, Symbol, or String but was #{cmd.class}" unless [Module, Method, Symbol, String].include?(cmd.class)
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
                    elsif cmd.class == Symbol || cmd.class == String
                      mod = cmd.to_s.split('::').reduce(Kernel){|last_mod, next_mod|
                        last_mod.const_get(next_mod.to_s.to_sym)
                      } rescue cmd
                      self.module_source(mod)
                    else
                      cmd
                    end
        }
      }
    end

    # Searches for the source location of the given module. Since modules can be defined in many locations, all source files
    # containing a definition for the given module will be joined.
    #
    # @param [Module] mod the module to be sourced
    # @return [String] a string representing the source of the given module or an empty string if no source file could be located
    def self.module_source(mod)
      return mod unless mod.class == Module
      method_sources = mod.singleton_methods(true).select { |sym| ![:included, :extended].include?(sym) }.map { |sym|
        mod.method(sym).source_location.first rescue nil
      }
      feature_sources = $LOADED_FEATURES.select{|file|
        name_match = File.dirname(file) == File.dirname(File.realpath($0))
        parent_match = File.dirname(File.dirname(file)) == File.dirname(File.dirname(File.realpath($0)))
        ancestor_match = File.dirname(File.dirname(File.dirname(file))) == File.dirname(File.dirname(File.dirname(File.realpath($0))))
        pwd_match = File.absolute_path(file).include?(Dir.pwd)
        final = if name_match || parent_match || ancestor_match || pwd_match # prevents unnecessary file reading
          (!File.read(file).match(/(class|module)\s+#{mod.name}/).nil?) rescue false
        else
          false
        end
        final
      }
      source_files = (method_sources + feature_sources).compact.uniq
      unless source_files.include?($0) # prevents unnecessary file reading
        source_files << $0 unless File.read($0).match(/(class|module)\s+#{mod.name}/).nil?
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
      return method unless method.class == Method
      method.comment + method.source
    end
  end
end
