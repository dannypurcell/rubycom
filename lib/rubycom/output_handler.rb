module Rubycom
  module OutputHandler

    # Prints the command_result if it is a basic type or a Yaml representation of command_result if it is not
    # basic types: String, NilClass, TrueClass, FalseClass, Fixnum, Float, Symbol
    #
    # @param [Object] command_result the result of a method call to be printed
    def self.process_output(command_result)
      std_output = nil
      std_output = command_result.to_yaml unless [String, NilClass, TrueClass, FalseClass, Fixnum, Float, Symbol].include?(command_result.class)
      $stdout.puts std_output || command_result
    end

  end
end
