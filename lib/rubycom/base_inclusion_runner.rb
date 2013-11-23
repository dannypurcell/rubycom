module Rubycom
  module BaseInclusionRunner

    # Calls the given run_fn with the given base and args if the base was
    # run from the command line in it's home folder or from an installed gem library
    #
    # @param [Array] the result from Kernel.caller as called from an included module within base
    # if the first caller entry matches $0 then the base module was executed from it's home folder
    # @param [Method|Proc] to be run if run criteria are satisfied
    # @param [Module] the base Module to test against and to send to the run_fn
    # @param [Array] args a String Array representing the arguments to be passed to run_fn
    # @return nil
    def self.run(caller, run_fn, base, args)
      base_file_path = caller.first.gsub(/:\d+:.+/, '')
      if base.class == Module && (base_file_path == $0 || self.is_executed_by_gem?(base_file_path))
        base.module_eval {
          run_fn.call(base, args)
        }
      end
      nil
    end

    # Determines whether the including module was executed by a gem binary
    #
    # @param [String] base_file_path the path to the including module's source file
    # @return [Boolean] true|false
    def self.is_executed_by_gem?(base_file_path)
      Gem.loaded_specs.map { |k, s|
        {k => {name: "#{s.name}-#{s.version}", executables: s.executables}}
      }.reduce({}, &:merge).map { |_, s|
        base_file_path.include?(s[:name]) && s[:executables].include?(File.basename(base_file_path))
      }.flatten.reduce(&:|)
    end

  end
end