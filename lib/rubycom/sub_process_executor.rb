module Rubycom

  class RubycomError < StandardError;
  end

  module SubProcessExecutor
    require 'open3'

    def self.execute_command(command, parameters)
      command, parameters = self.check(command, parameters)
      self.call_method(command, parameters)
    end

    def self.check(command, parameters)
      raise "#{command} should be a Method but was #{command.class}" if command.class != Method
      raise "#{parameters} should be a Hash but was #{parameters.class}" if parameters.class != Hash
      [command, parameters]
    end

    # Calls the given method with the given parameters in a sub process
    #
    # @param [Method] method the Method to call
    # @param [Hash] parameters a Hash mapping parameter names to their intended values
    # @return [Hash] a Hash containing the :in,:out,:err pipes for the subprocess
    def self.call_method(method, parameters={})
      params = method.parameters.map { |type, sym|
        raise RubycomError, "Missing required argument #{sym.to_s}" if (type == :req) && !parameters.has_key?(sym)
        parameters[sym]
      }
      if parameters.nil? || parameters.empty?
        c_in, c_out, c_err = Open3.popen3("ruby -e 'load \"#{method.source_location.first}\"; puts #{method.receiver}.public_method(:#{method.name}).call'")
      else
        c_in, c_out, c_err = Open3.popen3("ruby -e 'load \"#{method.source_location.first}\"; puts #{method.receiver}.public_method(:#{method.name}).call(*#{params})'")
      end
      {
          in: c_in,
          out: c_out,
          err: c_err
      }
    end

  end
end
