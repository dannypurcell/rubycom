require "#{File.dirname(__FILE__)}/commands.rb"

module Rubycom
  module Documentation

    def self.map_docs(commands_hsh, plugin=:yard)
      commands_hsh.map { |com_sym, hsh|
        case hsh[:type]
          when :module
            {
                com_sym => (Rubycom::Documentation.module(com_sym.to_s, hsh[:source], plugin)[:short_doc])
            }
          when :command
            {
                com_sym => (Rubycom::Documentation.command(com_sym.to_s, hsh[:source], plugin)[:short_doc])
            }
          else
            raise "DocumentationError: Unrecognized command type #{type} for #{com_sym}"
        end
      }.reduce(&:merge)
    end

    def self.module(name, source, plugin=:yard)
      case plugin
        when :yard
          load "#{File.dirname(__FILE__)}/documentation/yard_doc.rb"
          Rubycom::Documentation::YardDoc.module_doc(name, source)
        else
          raise "Cannot run module: No Documentation plugin found for #{plugin}"
      end
    end

    def self.command(name, source, plugin=:yard)
      case plugin
        when :yard
          load "#{File.dirname(__FILE__)}/documentation/yard_doc.rb"
          Rubycom::Documentation::YardDoc.command_doc(name, source)
        else
          raise "Cannot run command: No Documentation plugin found for #{plugin}"
      end
    end

    # @return [String] the usage message for Rubycom's default commands
    def self.get_default_commands_usage()
      <<-END.gsub(/^ {6}/, '')

      Default Commands:
      help                 - prints this help page
      job                  - run a job file
      register_completions - setup bash tab completion
      tab_complete         - print a list of possible matches for a given word
      END
    end

    # @return [String] the usage message for Rubycom's job runner
    def self.get_job_usage(base)
      <<-END.gsub(/^ {6}/, '')
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
      <<-END.gsub(/^ {6}/, '')
      Usage: #{base} register_completions
      END
    end

    def self.get_tab_complete_usage(base)
      <<-END.gsub(/^ {6}/, '')
      Usage: #{base} tab_complete <word>
      Parameters:
        [String] word the word or partial word to find matches for
      END
    end

  end
end
