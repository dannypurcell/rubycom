module Rubycom
  module CommandInterface
    require "#{File.dirname(__FILE__)}/helpers.rb"

    def self.build_interface(command, command_doc)
      <<-END.gsub(/ {6}/, '')
      #{self.build_usage(command, command_doc)}
      Description:
      #{command_doc[:full_doc].split("\n").map{|line| "  #{line}"}.join("\n").chomp}
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
        "<command> [args]"
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
        "#{self.build_others(tags[:others])}#{self.build_params(tags[:params])}#{self.build_returns(tags[:returns])}"
      else
        ""
      end
    end

    def self.build_others(other_tags)
      return nil if other_tags.nil? || other_tags.empty?
      "\nTags:\n  #{other_tags.map { |line| "  #{line}" }.join.chomp}"
    end

    def self.build_params(param_tags)
      return nil if param_tags.nil? || param_tags.empty?
      "\nParameters:\n#{param_tags.map { |line| "  #{line}" }.join.chomp}"
    end

    def self.build_returns(return_tags)
      return nil if return_tags.nil? || return_tags.empty?
      "\nReturns:\n#{return_tags.map { |line| "  #{line}" }.join.chomp}"
    end

  end
end
