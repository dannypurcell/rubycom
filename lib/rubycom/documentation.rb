require "#{File.dirname(__FILE__)}/commands.rb"

module Rubycom
  module Documentation

    # Retrieves the summary for each command method in the given Module
    #
    # @param [Module] base the module which invoked 'include Rubycom'
    # @return [String] the summary for each command method in the given Module
    def self.get_summary(base)
      Commands.get_top_level_commands(base).each_with_index.map { |sym, index|
        "#{"Commands:\n" if index == 0}" << self.get_command_summary(base, sym, self.get_separator(sym, Commands.get_longest_command_name(base).length))
      }.reduce(:+) or "No Commands found for #{base}."
    end

    # Creates a separator with the appropriate spacing to line up a command/description pair in a command list
    #
    # @param [Symbol] sym
    # @param [Integer] spacer_length
    # @return [String] a spaced separator String for use in a command/description list
    def self.get_separator(sym, spacer_length=0)
      [].unshift(" " * (spacer_length - sym.to_s.length)).join << "  -  "
    end

    # Retrieves the summary for the given command_name
    #
    # @param [Module] base the module which invoked 'include Rubycom'
    # @param [String] command_name the command to retrieve usage for
    # @return [String] a summary of the given command_name
    def self.get_command_summary(base, command_name, separator = '  -  ')
      raise CLIError, "Can not get usage for #{command_name} with base: #{base||"nil"}" if base.nil? || !base.respond_to?(:included_modules)
      return 'No command specified.' if command_name.nil? || command_name.length == 0
      if base.included_modules.map { |mod| mod.name.to_sym }.include?(command_name.to_sym)
        begin
          mod_const = Kernel.const_get(command_name.to_sym)
          desc = File.read(mod_const.public_method(mod_const.singleton_methods().first).source_location.first).split(//).reduce("") { |str, c|
            unless str.gsub("\n", '').gsub(/\s+/, '').include?("module#{mod_const}")
              str << c
            end
            str
          }.split("\n").select { |line| line.strip.match(/^#/) && !line.strip.match(/^#!/) }.map { |line| line.strip.gsub(/^#+/, '') }.join("\n")
        rescue
          desc = ""
        end
      else
        raise CLIError, "Invalid command for #{base}, #{command_name}" unless base.public_methods.include?(command_name.to_sym)
        desc = self.get_doc(base.public_method(command_name.to_sym))[:desc].join("\n") rescue ""
      end
      (desc.nil?||desc=='nil'||desc.length==0) ? "#{command_name}\n" : self.get_formatted_summary(command_name, desc, separator)
    end

    # Arranges the given command_name and command_description with the separator in a standard format
    #
    # @param [String] command_name the command format
    # @param [String] command_description the description for the given command
    # @param [String] separator optional separator to use
    def self.get_formatted_summary(command_name, command_description, separator = '  -  ')
      width = 95
      prefix = command_name.to_s.split(//).map { " " }.join + separator.split(//).map { " " }.join
      line_width = width - prefix.length
      description_msg = command_description.gsub(/(.{1,#{line_width}})(?: +|$)\n?|(.{#{line_width}})/, "#{prefix}"+'\1\2'+"\n")
      "#{command_name}#{separator}#{description_msg.lstrip}"
    end

    # Retrieves the usage description for the given Module with a list of command methods
    #
    # @param [Module] base the module which invoked 'include Rubycom'
    # @return [String] the usage description for the module with a list of command methods
    def self.get_usage(base)
      return '' if base.nil? || !base.respond_to?(:included_modules)
      return '' if Commands.get_top_level_commands(base).size == 0
      "Usage:\n    #{base} <command> [args]\n\n" << self.get_summary(base)
    end

    # Retrieves the usage description for the given command_name
    #
    # @param [Module] base the module which invoked 'include Rubycom'
    # @param [String] command_name the command to retrieve usage for
    # @param [Array] args the remaining args other than the command_name, used of sub-command look-ups
    # @return [String] the detailed usage description for the given command_name
    def self.get_command_usage(base, command_name, args=[])
      raise CLIError, "Can not get usage for #{command_name} with base: #{base||"nil"}" if base.nil? || !base.respond_to?(:included_modules)
      return 'No command specified.' if command_name.nil? || command_name.length == 0
      if base.included_modules.map { |mod| mod.name.to_sym }.include?(command_name.to_sym)
        if args.empty?
          self.get_usage(eval(command_name.to_s))
        else
          self.get_command_usage(eval(command_name.to_s), args[0], args[1..-1])
        end
      else
        raise CLIError, "Invalid command for #{base}, #{command_name}" unless base.public_methods.include?(command_name.to_sym)
        m = base.public_method(command_name.to_sym)
        method_doc = self.get_doc(m) || {}

        msg = "Usage: #{m.name}#{self.get_param_usage(m)}\n"
        msg << "Parameters:\n    " unless m.parameters.empty?
        msg << "#{method_doc[:param].join("\n    ")}\n" unless method_doc[:param].nil?
        msg << "Returns:\n    " unless method_doc[:return].nil?
        msg << "#{method_doc[:return].join("\n    ")}\n" unless method_doc[:return].nil?
        msg
      end
    end

    # Discovers the given Method's parameters and uses them to build a formatted usage string
    #
    # @param [Method] method the Method object to generate usage for
    def self.get_param_usage(method)
      return "" if method.parameters.nil? || method.parameters.empty?
      Arguments.get_param_definitions(method).group_by { |_, hsh|
        hsh[:type]
      }.map { |key, val_arr|
        vals = Hash[*val_arr.flatten]
        {
            key => if key == :opt
                     vals.map { |param, val_hsh| "-#{param.to_s}=#{val_hsh[:default]}" }
                   elsif key == :req
                     vals.keys.map { |param| " <#{param.to_s}>" }
                   else
                     vals.keys.map { |param| " [&#{param.to_s}]" }
                   end
        }
      }.reduce(&:merge).map { |type, param_arr|
        if type == :opt
          " [#{param_arr.join("|")}]"
        else
          param_arr.join
        end
      }.join
    end

    # Retrieves the given method's documentation from it's source code
    #
    # @param [Method] method the Method who's documentation should be retrieved
    # @return [Hash] a Hash representing the given Method's documentation, documentation parsed as follows:
    #                :desc = the first general method comment lines,
    #                :word = each @word comment (i.e.- a line starting with @param will be saved as :param => ["line"])
    def self.get_doc(method)
      method.comment.split("\n").map { |line|
        line.gsub(/#\s*/, '') }.group_by { |doc|
        if doc.match(/^@\w+/).nil?
          :desc
        else
          doc.match(/^@\w+/).to_s.gsub('@', '').to_sym
        end
      }.map { |key, val|
        Hash[key, val.map { |val_line| val_line.gsub(/^@\w+/, '').lstrip }.select { |line| line != '' }]
      }.reduce(&:merge)
    end

    def self.get_default_commands_usage()
      <<-END.gsub(/^ {6}/,'')

      Default Commands:
      help                 - prints this help page
      job                  - run a job file
      register_completions - setup bash tab completion
      tab_complete         - print a list of possible matches for a given word
      END
    end

    def self.get_job_usage(base)
      <<-END.gsub(/^ {6}/,'')
      Usage: #{base} job <job_path>
      Parameters:
        [String] job_path the path to the job yaml to be run
      Details:
      A job yaml is any yaml file which follows the format below.
        * The env: key shown below is optional
        * The steps: key must contain a set of numbered steps as shown
        * The desc: key shown below is an optional context for the job's log output
          * Other than cmd: there may be as many keys in a numbered command as you choose
      ---
      env:
        test_msg: Hello World
        test_arg: 123
        working_dir: ./test
      steps:
        1:
          desc: Run test command with environment variable
          test_context: Some more log context
          cmd: ruby env[working_dir]/test.rb test_command env[test_msg]
        2:
          cmd: ls env[working_dir]
      END
    end

    def self.get_register_completions_usage(base)
      <<-END.gsub(/^ {6}/,'')
      Usage: #{base} register_completions
      END
    end

    def self.get_tab_complete_usage(base)
      <<-END.gsub(/^ {6}/,'')
      Usage: #{base} tab_complete <word>
      Parameters:
        [String] word the word or partial word to find matches for
      END
    end

  end
end