module OptparsePlugin
  require 'optparse'
  # Prints command line interface usage in a format useful for representing a ruby module.
  # Parses the given args for the given options. Parsing will stop either when the parser encounters
  # a command name or runs out of args.
  # !modifies the args parameter in place
  #
  # @param [String] name the name of the module
  # @param [String] documentation the full module description
  # @param [Hash] commands a mapping of command names to summary documentation for the command
  # @param [Array] options the command line options to print/parse
  # @param [Array] args to be parsed
  # @return [Hash] mapping :args to the remaining args, :opts to a hash mapping option names to parsed values,
  # and :out to the command line interface output which can be used as help for the given inputs.
  def self.module(name, documentation, commands, options, args=ARGV)
    commands = {} if commands.nil?
    parsed_options = {}
    opts = OptionParser.new { |opts|
      opts.banner = <<-EOS.gsub(/^ {8}/, '')
        Usage: #{name} <command> [options]
        Description:
        #{documentation.split("\n").map { |line| "  " << line }.join("\n")}
        Commands:
        #{Rubycom::CLI::Helpers.format_command_list(commands)}
        #{"Options:\n" unless options.empty?}
      EOS
      options.each { |option, doc|
        opts.on("-#{option.to_s[0]}", "--#{option.to_s}", doc) { |opt|
          parsed_options[option] = opt
        }
      }
    }
    command_names = commands.map { |k, _| k.to_s }
    begin
      args = opts.order(args) { |arg|
        opts.terminate(arg) if command_names.include?(arg)
      }
    rescue OptionParser::ParseError => e
      $stderr.puts "Error during option parsing: #{e}"
      $stderr.puts opts.to_s.rstrip
      raise e
    end
    {
        args: args,
        opts: parsed_options,
        out: opts.to_s.rstrip
    }
  end

  # Prints command line interface usage in a format useful for representing a ruby method within a module.
  # Parses the given args for the given options. Parsing will stop either when the parser runs out of args.
  # !modifies the args parameter in place
  #
  # @param [String] name the name of the ruby method
  # @param [String] documentation the full method description
  # @param [Hash] parameters a mapping of the method's parameter names to param documentation
  # @param [Array] args to be parsed
  # @return [Hash] mapping :args to the remaining args, :opts to a hash mapping option names to parsed values,
  # and :out to the command line interface output which can be used as help for the given inputs.
  def self.command(name, documentation, parameters, args=ARGV)
    parsed_options = {}
    opts = OptionParser.new() { |opts|
      opts.banner = <<-EOS.gsub(/^ {8}/, '')
        Usage: #{name} [options]
        Description:
        #{documentation.split("\n").map { |line| "  " << line }.join("\n")}
        #{"Parameters:\n" unless parameters.empty?}
      EOS
      parameters.each { |param, doc|
        opts.on("-#{param.to_s.first}", "--#{param.to_s}", doc) { |opt|
          parsed_options[param] = opt
        }
      }
    }
    begin
      args = opts.order(args)
    rescue OptionParser::ParseError => e
      $stderr.puts "Error during option parsing: #{e}"
      $stderr.puts opts.to_s.rstrip
      raise e
    end
    {
        args: args,
        opts: parsed_options,
        out: opts.to_s.rstrip
    }
  end

end
