module Rubycom
  module OutputHandler

    def self.process_output(command_result)
      if command_result.is_a?(Hash) && [:in, :out, :err].each { |sym| command_result.has_key?(sym) }
        command_result[:in].reopen($stdin)
        ot = Thread.new{
          command_result[:out].each{|line|
            $stdout.puts line
          }
        }
        et =Thread.new{
          command_result[:err].each{|line|
            $stderr.puts line
          }
        }
        ot.join
        et.join
      else
        std_output = nil
        std_output = command_result.to_yaml unless [String, NilClass, TrueClass, FalseClass, Fixnum, Float, Symbol].include?(command_result.class)
        $stdout.puts std_output || command_result
      end
    end

  end
end
