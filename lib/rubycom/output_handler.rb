module Rubycom
  module OutputHandler

    def self.process_output(command_result)
      std_output = nil
      std_output = command_result.to_yaml unless [String, NilClass, TrueClass, FalseClass, Fixnum, Float, Symbol].include?(command_result.class)
      $stdout.puts std_output || command_result
    end

  end
end
