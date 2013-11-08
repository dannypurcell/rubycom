module Rubycom
  module CommandInterface
    require "#{File.dirname(__FILE__)}/helpers.rb"

    # Uses #build_usage and #build_details to create a structured text output from the given command and doc hash
    #
    # @param [Module|Method|String] command the command to be named in the output
    # @param [Hash] command_doc keys should include :full_doc and any keys required by #build_usage and #build_details
    # @return [String] a structured string suitable for printing to the console as a command usage document
    def self.build_interface(command, command_doc)
      return '' if command.nil?
      return '' if command_doc.nil?
      "#{self.build_usage(command, command_doc)}\n"+
      "Description:\n"+
      "#{command_doc.fetch(:full_doc, '').split("\n").map{|line| "  #{line}"}.join("\n").chomp}\n"+
      "#{self.build_details(command, command_doc)}"
    end

    # Uses #build_options to create a usage banner for use in a command usage document
    #
    # @param [Module|Method|String] command the command to be named in the output
    # @param [Hash] command_doc keys should include any keys required by #build_options
    # @return [String] a structured text representation of usage patterns for the given command and doc hash
    def self.build_usage(command, command_doc)
      return '' if command.nil?
      command_use = if File.basename($0, File.extname($0)).gsub("_", '') == command.name.to_s.downcase
                      File.basename($0)
                    else
                      command.name.to_s
                    end
      "Usage: #{command_use} #{self.build_options(command, command_doc)}"
    end

    # Creates a structured text representation of usage patterns for the given command and doc hash
    #
    # @param [Module|Method|String] command the class will be used to determine the overall usage pattern
    # @param [Hash] command_doc keys should include :parameters and each parameter should be a hash including keys :type, :param_name, :default
    # @return [String] a structured text representation of usage patterns for the given command and doc hash
    def self.build_options(command, command_doc)
      return '' if command_doc.nil?
      if command.class == Module
        "<command> [args]"
      elsif command.class == Method
        args, opts = command_doc.fetch(:parameters).map { |param|
          if param.fetch(:type) == :req
            "<#{param[:param_name]}>"
          else
            "[--#{param[:param_name]} #{param[:default]}]"
          end
        }.group_by { |p| p.start_with?('<') }.map { |_, group| group.join(' ') }
        "#{args} #{opts}"
      else
        ""
      end
    end

    # Creates a structured list of either sub commands or parameters based on the class of command
    # Calls #build_tags if command is a Method
    #
    # @param [Module|Method|String] command the class will be used to determine the usage structure
    # @param [Hash] command_doc keys should include :parameters and each parameter should be a hash including keys :type, :param_name, :default
    # @return [String] a structured text representing a list of sub commands or a list of parameters
    def self.build_details(command, command_doc)
      if command.class == Module
        sub_commands = Rubycom::Helpers.format_command_list(command_doc[:sub_command_docs], 90, '  ').join()
        (sub_commands.empty?)? '' : "Sub Commands:\n#{sub_commands}"
      elsif command.class == Method
        tags = self.build_tags(Rubycom::Helpers.format_tags(command_doc[:tags]))
        "#{tags[:others]}#{tags[:params]}#{tags[:returns]}"
      else
        ""
      end
    end

    # Creates a structured text representing the given documentation tags
    #
    # @param [Hash] tags :params|:returns|:others => [Strings]
    # @return [Hash] the given key => String representing the list of tags
    def self.build_tags(tags)
      return '' if tags.nil? || tags.empty?
      tags.map{|k,val_arr|
        val = val_arr.map { |line| "  #{line}" }.join.chomp
        {
            k => if k == :params
                   (val.empty?)? '' : "\nParameters:\n#{val}"
                 elsif k == :returns
                   (val.empty?)? '' : "\nReturns:\n#{val}"
                 else
                   (val.empty?)? '' : "\nTags:\n#{val}"
                 end
        }
      }.reduce({}, &:merge)
    end

  end
end
