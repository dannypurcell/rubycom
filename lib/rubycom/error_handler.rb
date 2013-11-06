module Rubycom
  module ErrorHandler

    # Prints the error followed by the command line interface text
    #
    # @param [Error] e the error to be printed
    # @param [String] cli_output the command line interface text to be printed
    def self.handle_error(e, cli_output)
      $stderr.puts e
      $stderr.puts
      $stderr.puts cli_output
    end

  end
end
