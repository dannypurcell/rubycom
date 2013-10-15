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
      params = method.parameters.map { |type,sym|
        raise RubycomError, "Missing required argument #{sym.to_s}" if (type == :req) && !parameters.has_key?(sym)
        parameters[sym]
      }
      (parameters.nil? || parameters.empty?) ? method.call : method.call(*params)
    end

  end
end
