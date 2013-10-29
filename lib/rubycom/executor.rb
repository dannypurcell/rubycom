module Rubycom
  module Executor

    # Calls the given method with the given parameters
    #
    # @param [Method] method the Method to call
    # @param [Hash] parameters a Hash mapping parameter names to their intended values
    # @return the result of the Method call
    def self.execute_command(method, parameters={})
      raise "#{method} should be a Method but was #{method.class}" if method.class != Method
      raise "#{parameters} should be a Hash but was #{parameters.class}" if parameters.class != Hash
      params = method.parameters.reject{|type,_|type == :rest}.map { |_, sym|
        raise ExecutorError, "parameters should include values for all non * method parameters. Missing value for #{sym.to_s}" unless parameters.has_key?(sym)
        parameters[sym]
      }
      unless method.parameters.select{|type,_|type == :rest}.first.nil? #if there is a * param
        params = params + parameters[method.parameters.select{|type,_|type == :rest}.first[1]] #add in the values which were marked for the * param
      end
      (parameters.nil? || parameters.empty?) ? method.call : method.call(*params)
    end

  end
end
