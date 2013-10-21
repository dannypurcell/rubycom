module Rubycom

  class RubycomError < StandardError;
  end

  module Executor

    def self.execute_command(command, parameters)
      command, parameters = self.check(command, parameters)
      self.call_method(command, parameters)
    end

    def self.check(command, parameters)
      raise "#{command} should be a Method but was #{command.class}" if command.class != Method
      raise "#{parameters} should be a Hash but was #{parameters.class}" if parameters.class != Hash
      [command, parameters]
    end

    # Calls the given method with the given parameters
    #
    # @param [Method] method the Method to call
    # @param [Hash] parameters a Hash mapping parameter names to their intended values
    # @return the result of the Method call
    def self.call_method(method, parameters={})
      params = method.parameters.reject{|type,_|type == :rest}.map { |_, sym|
        raise RubycomError, "parameters should include values for all method parameters. Missing value for #{sym.to_s}" if !parameters.has_key?(sym)
        parameters[sym]
      }
      unless method.parameters.select{|type,_|type == :rest}.first.nil? #if there is a * param
        params = params + parameters[method.parameters.select{|type,_|type == :rest}.first[1]] #add in the values which were marked for the * param
      end
      (parameters.nil? || parameters.empty?) ? method.call : method.call(*params)
    end

  end
end
