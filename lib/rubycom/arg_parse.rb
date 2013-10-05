require 'parslet'
require 'yaml'

module Rubycom
  module ArgParse
    class ArgParser < Parslet::Parser
      rule(:space)             { match('\s').repeat(1) }
      rule(:space?)            { space.maybe }

      rule(:word)              { match('\w').repeat(1) >> space? }

      rule(:short_opt)         { match('-') >> word }
      rule(:negated_short_opt) { match('-no-') >> word }
      rule(:long_opt)          { match('--') >> word }
      rule(:negated_long_opt)  { match('--no-') >> word }

      rule(:expression)        { word | short_opt | negated_short_opt | long_opt | negated_long_opt }

      root :expression
    end

    def self.parse(*args)
      args = self.check(args)
      arg_string = args.join(' ')
      begin
        ArgParser.new.parse(arg_string)
      rescue Parslet::ParseFailed => failure
        puts failure.cause.ascii_tree
      end
    end

    def self.check(*args)
      raise "args should be an array of Strings" if args.map{|arg|arg.class}.uniq.length > 1
      args
    end

    def self.parse_args(arguments)
      arguments.map { |arg|
        self.parse_arg(arg)
      }.group_by { |hsh|
        hsh.keys.first
      }.map { |key, arr|
        (key == :rubycom_non_opt_arg) ? Hash[key, arr.map { |hsh| hsh.values }.flatten(1)] : Hash[key, arr.map { |hsh| hsh.values.first }.reduce(&:merge)]
      }.reduce(&:merge) || {}
    end

    # Uses YAML.load to parse the given String
    #
    # @param [String] arg a String representing the argument to be parsed
    # @return [Object] the result of parsing the given arg with YAML.load
    def self.parse_arg(arg)
      return Hash[:rubycom_non_opt_arg, nil] if arg.nil?
      if arg.is_a?(String) && ((arg.match(/^[-]{3,}\w+/) != nil) || ((arg.match(/^[-]{1,}\w+/) == nil) && (arg.match(/^\w+=/) != nil)))
        raise RubycomError, "Improper option specification, options must start with one or two dashes. Received: #{arg}"
      elsif arg.is_a?(String) && arg.match(/^(-|--)\w+[=|\s]{1}/) != nil
        k, v = arg.partition(/^(-|--)\w+[=|\s]{1}/).select { |part|
          !part.empty?
        }.each_with_index.map { |part, index|
          if index == 0
            part.chomp('=').gsub(/^--/, '').gsub(/^-/, '').strip.to_sym
          else
            if part.start_with?("#") || part.start_with?("!")
              "#{part}"
            else
              (YAML.load(part) rescue "#{part}")
            end
          end
        }
        Hash[k, v]
      else
        begin
          parsed_arg = "#{arg}"
          unless arg.start_with?("#") || arg.start_with?("!")
            parsed_arg = YAML.load("#{arg}")
          end
        rescue Exception
          parsed_arg = "#{arg}"
        end
        Hash[:rubycom_non_opt_arg, parsed_arg]
      end
    end

  end
end
