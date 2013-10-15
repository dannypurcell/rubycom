module Rubycom
  module ErrorHandler

    def self.handle_error(e, cli_output)
      $stderr.puts e
      $stderr.puts
      $stderr.puts cli_output
    end

  end
end
