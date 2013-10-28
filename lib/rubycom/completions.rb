module Rubycom
  module Completions

    # Discovers a list of possible matches to the given arguments
    # Intended for use with bash tab completion
    #
    # @param [Module] base the module which invoked 'include Rubycom'
    # @param [Array] arguments a String Array representing the arguments to be matched
    # @param [Module] command_plugin the plugin to use for retrieving commands
    # @return [Array] a String Array including the possible matches for the given arguments
    def self.tab_complete(base, arguments, command_plugin)
      return [] unless base.class == Module
      return [] unless command_plugin.class == Module
      arguments = [] if arguments.nil?
      args = (arguments.include?('tab_complete')) ? arguments[2..-1] : arguments
      matches = %w()
      if args.nil? || args.empty?
        matches = command_plugin.get_top_level_commands(base)[base.to_s.to_sym].map { |sym,_| sym.to_s }
      elsif args.length == 1
        matches = command_plugin.get_top_level_commands(base)[base.to_s.to_sym].map { |sym,_| sym.to_s }.select { |word| !word.match(/^#{args[0]}/).nil? }
        if matches.size == 1 && matches[0] == args[0]
          matches = self.tab_complete(Kernel.const_get(args[0].to_sym), args[1..-1], command_plugin)
        end
      elsif args.length > 1
        begin
          matches = self.tab_complete(Kernel.const_get(args[0].to_sym), args[1..-1], command_plugin)
        rescue Exception
          matches = %w()
        end
      end unless base.nil?
      matches = %w() if matches.nil? || matches.include?(args[0])
      matches
    end

    # Inserts a tab completion into the current user's .bash_profile with a command entry to register the function for
    # the current running ruby file
    #
    # @param [Module] base the module which invoked 'include Rubycom'
    # @return [String] a message indicating the result of the command
    def self.register_completions(base)
      completion_function = <<-END.gsub(/^ {6}/, '')

      _#{base}_complete() {
        COMPREPLY=()
        local completions="$(ruby #{File.absolute_path($0)} tab_complete ${COMP_WORDS[*]} 2>/dev/null)"
        COMPREPLY=( $(compgen -W "$completions") )
      }
      complete -o bashdefault -o default -o nospace -F _#{base}_complete #{$0.split('/').last}
      END

      already_registered = File.readlines("#{Dir.home}/.bash_profile").map { |line| line.include?("_#{base}_complete()") }.reduce(:|) rescue false
      if already_registered
        "Completion function for #{base} already registered."
      else
        File.open("#{Dir.home}/.bash_profile", 'a+') { |file|
          file.write(completion_function)
        }
        "Registration complete, run 'source #{Dir.home}/.bash_profile' to enable auto-completion."
      end
    end
  end
end
