module Rubycom
  module CommandInterface
    require "#{File.dirname(__FILE__)}/helpers.rb"

    def self.build_interface(command, command_doc)
      <<-END.gsub(/ {6}/, '')
      #{self.build_usage(command, command_doc)}
      Description:
      #{command_doc[:full_doc]}
      #{self.build_details(command, command_doc)}
      END
    end

    def self.build_usage(command, command_doc)
      command_use = if File.basename($0, File.extname($0)).gsub("_", '') == command.name.to_s.downcase
                      File.basename($0)
                    else
                      command.name.to_s
                    end
      "Usage: #{command_use} #{self.build_options(command, command_doc)}"
    end

    def self.build_options(command, command_doc)
      if command.class == Module
        "[command]"
      elsif command.class == Method
        args, opts = command_doc[:parameters].map { |param|
          if param[:required]
            "<#{param[:param_name]}>"
          else
            "#{param[:param_name]}"
          end
        }.group_by { |p| p.start_with?('<') }.map { |k, group| (k) ? group.join(' ') : group.join('|') }
        "#{args} [#{opts}]"
      else
        ""
      end
    end

    def self.build_details(command, command_doc)
      if command.class == Module
        sub_commands = Rubycom::Helpers.format_command_list(command_doc[:sub_command_docs]).map { |line| "  #{line}" }.join.chomp
        (sub_commands.empty?)? '' : "Sub Commands:\n#{sub_commands}"
      elsif command.class == Method
        tags = Rubycom::Helpers.format_tags(command_doc[:tags])
        other_tags = (tags[:others].empty?) ? '' : "Tags:\n  #{tags[:others].map { |line| "  #{line}" }.join.chomp}"
        <<-END.gsub(/ {8}/, '')
        #{other_tags}
        Parameters:
          #{tags[:params].map { |line| "  #{line}" }.join.chomp}
        Returns:
          #{tags[:returns].map { |line| "  #{line}" }.join.chomp}
        END
      else
        ""
      end
    end

  end
end
