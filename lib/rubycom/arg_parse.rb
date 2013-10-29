module Rubycom
  module ArgParse
    require 'parslet'
    require 'yaml'

    # Runs a parser against the given Array of arguments to match command argument, option, and flag patterns.
    #
    # @param [Array] command_line an array of strings representing the arguments taken from the command line
    # @return [Hash] :args => Array of arguments, :opts => Hash mapping each unique option/flag to their values
    def self.parse_command_line(command_line)
      raise ArgumentError, "command_line should be String or Array but was #{command_line.class}" unless [String, Array].include?(command_line.class)
      command_line = command_line.dup
      command_line = [command_line] if command_line.class == String
      command_line = self.combine_options(command_line)
      begin
        command_line.map { |word|
          ArgTransform.new.apply(ArgParser.new.parse(word))
        }.reduce({}) { |acc, n|
          # the handlers for opt and flag accumulate all unique mentions of an option name
          if n.has_key?(:opt)
            acc[:opts] = {} unless acc.has_key?(:opts)
            acc[:opts] = acc[:opts].update(n[:opt]) { |key, old, new|
              if old.class == Array
                acc[:opts][key] = old << new
              else
                acc[:opts][key] = [old] << new
              end
            }
          elsif n.has_key?(:flag)
            acc[:opts] = {} unless acc.has_key?(:opts)
            acc[:opts] = acc[:opts].update(n[:flag]) { |key, old, new|
              if old.class == Array
                combined = old
              else
                combined = [old]
              end

              if new.class == Array
                new.each { |new_flag|
                  combined << new_flag
                }
              else
                combined << new
              end

              acc[:opts][key] = combined
            }
          else
            acc[:args] = [] unless acc.has_key?(:args)
            acc[:args] << n[:arg]
          end
          acc
        }
      rescue Parslet::ParseFailed => failure
        raise ArgParseError, "Arguments could not be parsed.", failure
      end
    end

    # Matches a word representing an optional key to the separator and/or value which goes with the key
    #
    # @param [Array] command_line an array of strings representing the arguments taken from the command line
    # @return [Array] an Array of Strings with matched items combined into one entry per matched set
    def self.combine_options(command_line)
      command_line.reduce([]) { |acc, next_word|
        if next_word == '=' || (!next_word.start_with?('-') && acc.last.to_s.start_with?('-') && acc.last.to_s.end_with?('='))
          acc[-1] = acc[-1].dup << next_word
          acc
        elsif next_word == '=' || (!next_word.start_with?('-') && acc.last.to_s.start_with?('-') && !(acc.last.to_s.include?('=') || acc.last.to_s.include?(' ')))
          acc[-1] = acc[-1].dup << ' ' << next_word
          acc
        else
          acc << next_word
        end
      }
    end

    # Comprised of grammar rules which determine whether a given string is an argument, option, or flag.
    # Calling #parse with a String on an instance of this class will return a nested hash structure which identifies the
    # patterns recognized in the given string.
    # In order to use this parser on a command line argument array, it may be necessary to pre-join optional argument
    # keys to their values such that each item in the array is either a complete argument, complete optional-argument,
    # or a flag.
    #
    # Example:
    #   Rubycom::ArgParse::ArgParser.new.parse("-test_arg = test")
    #   => {:opt=>{:key=>"-test_arg"@0, :sep=>" = "@9, :val=>"test"@12}}
    class ArgParser < Parslet::Parser
      rule(:space) { match('\s').repeat(1) }
      rule(:eq) { match('=') }
      rule(:separator) { (eq | (space >> eq >> space) | space) }
      rule(:escape_char) { match(/\\/) }
      rule(:escaped_char) { escape_char >> any }
      rule(:d_quote) { escape_char.absent? >> match(/"/) }
      rule(:s_quote) { escape_char.absent? >> match(/'/) }

      rule(:double_escaped) { d_quote >> (escape_char.absent? >> match(/[^"]/)).repeat >> d_quote }
      rule(:single_escaped) { s_quote >> (escape_char.absent? >> match(/[^']/)).repeat >> s_quote }
      rule(:escaped_word) { single_escaped | double_escaped }
      rule(:raw_word) { (escaped_char | (separator.absent? >> any)).repeat(1) }
      rule(:word) { raw_word | single_escaped | double_escaped }
      rule(:list) { word >> (match(',') >> word).repeat(1) }

      rule(:short) { match('-') }
      rule(:long) { short >> short }
      rule(:neg_opt_prefix) { (long | short) >> (str('no-') | str('NO-')) >> word }
      rule(:opt_prefix) { (long | short) >> word }

      rule(:arg) { any.repeat }
      rule(:flag) { (neg_opt_prefix | opt_prefix) }
      rule(:opt) { opt_prefix.as(:key) >> separator.as(:sep) >> (list | word).as(:val) }

      rule(:expression) { opt.as(:opt) | flag.as(:flag) | arg.as(:arg) }

      root :expression
    end

    # Parslet transformer intended for use with ArgParser. Uses functions in Rubycom::ArgParse to clean up a structure
    # identified by the parser and convert values to basic types.
    #
    # Example:
    #   ArgTransform.new.apply(ArgParser.new.parse("-test_arg = test"))
    #   => {:opt=>{"test_arg"=>"test"}}
    class ArgTransform < Parslet::Transform
      rule(:arg => simple(:arg)) { Rubycom::ArgParse.transform(:arg, arg) }
      rule(:opt => subtree(:opt)) { Rubycom::ArgParse.transform(:opt, opt) }
      rule(:flag => simple(:flag)) { Rubycom::ArgParse.transform(:flag, flag) }
    end

    # Calls one of the transform functions according to the matched_type
    #
    # @param [Symbol] matched_type :arg, :opt, :flag will transform the value according to the corresponding transform function.
    # anything else will extract the value as a string
    # @param [Hash|Parslet::Slice] val a possibly nested Hash structure or a Slice. Hashes are returned by the parser when
    # it matches a complex pattern, a Slice will be returned when the matched pattern is not tree like.
    # @return [Hash] :arg => value | :opt|:flag => a Hash mapping keys to values
    def self.transform(matched_type, val)
      case matched_type
        when :arg
          val = Rubycom::ArgParse.transform_arg(val.str.strip)
        when :opt
          val = Rubycom::ArgParse.transform_opt(val)
        when :flag
          val = Rubycom::ArgParse.transform_flag(val.str.strip)
        else
          val = val.str.strip
      end
      {
          matched_type => val
      }
    end

    # Uses #load_string to resolve the ruby type for the given string
    #
    # @param [String] match_string a string identified as an argument
    # @return [Object] the result of a call to #load_string
    def self.transform_arg(match_string)
      self.load_string(match_string)
    end

    # Uses #load_string to resolve the ruby type for the value in the given Hash
    #
    # @param [Hash] subtree a structure identified as an option, must have keys :key, :sep, :val
    # @return [Object] the result of a call to #load_string
    def self.transform_opt(subtree)
      value = self.load_opt_value(subtree[:val].str.split(','))
      {
          subtree[:key].str.reverse.chomp('-').chomp('-').reverse => value
      }
    end

    # Uses #load_string to load a single string or array of strings
    #
    # @param [Array] value containing the string(s) to be loaded
    # @return [Object] the result of a call to #load_string
    def self.load_opt_value(value)
      (value.length == 1) ? self.load_string(value.first) : value.map { |v| self.load_string(v) }
    end

    # Uses YAML.load to resolve the ruby type for the given string
    #
    # @param [String] string to be loaded
    # @return [Object] the result of a call to YAML.load(string) or the given string if it could not be parsed
    def self.load_string(string)
      if string.start_with?('#') || string.start_with?('!')
        result = string
      else
        begin
          result = YAML.load(string)
        rescue Exception => e
          result = string
        end
      end
      result
    end

    # Resolves the type and values for the given flag string
    #
    # @param [String] match_string a string identified as a flag, should start with a - or -- and contain no spaces
    # @return [Hash] flag_key(s) => true|false | an array of true|false if there were multiple mentions of the same short flag key
    def self.transform_flag(match_string)
      if match_string.start_with?('--')
        long_flag = match_string.reverse.chomp('-').chomp('-').reverse
        long_flag_key = long_flag.sub(/no-|NO-/, '')
        long_flag_val = (long_flag.start_with?('no-')||long_flag.start_with?('NO-')) ? false : true
        {
            long_flag_key => long_flag_val
        }
      else
        short_flag = match_string.reverse.chomp('-').reverse
        short_flag_key = short_flag.sub(/no-|NO-/, '')
        short_flag_val = (short_flag.start_with?('no-')||short_flag.start_with?('NO-')) ? false : true
        short_flag_key.split(//).map { |k|
          {
              k => short_flag_val
          }
        }.reduce({}) { |acc, n|
          acc.update(n) { |_, old, new|
            if old.class == Array
              old << new
            else
              [old] << new
            end
          }
        }
      end
    end

  end
end
