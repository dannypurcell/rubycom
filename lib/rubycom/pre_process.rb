module Rubycom
  module PreProcess

    def self.pre_process(base, parsed_command_line, sourced_commands, documented_commands)
      base, parsed_command_line, sourced_commands, documented_commands = self.check(base, parsed_command_line, sourced_commands, documented_commands)
      {
          executor: {},
          cli: {}
      }
    end

    def self.check(base, parsed_command_line, sourced_commands, documented_commands)
      [base, parsed_command_line, sourced_commands, documented_commands]
    end

  end
end
