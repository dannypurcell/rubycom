module Rubycom
  module ArgParse
    require 'parslet'
    require 'yaml'

    class ArgParseError < StandardError;
    end

    def self.parse_command_line(command_line)
      begin
        ArgTransform.new.apply(
            ArgParser.new.parse(
                self.check(command_line)
            )
        )
      rescue Parslet::ParseFailed => failure
        puts failure.cause.ascii_tree
      end
    end

    def self.check(command_line)
      command_line = command_line.join(' ') if command_line.class == Array
      raise "args should be String but was #{command_line.class}" unless command_line.class == String
      command_line << ' '
    end

    class ArgParser < Parslet::Parser
      rule(:space) { match('\s').repeat(1) }
      rule(:eq) { match('=') }
      rule(:separator) { (eq | (space >> eq >> space) | space) }

      rule(:double_escaped) { match(/"/) >> match(/[^"]/).repeat >> match(/"/) }
      rule(:single_escaped) { match(/'/) >> match(/[^']/).repeat >> match(/'/) }
      rule(:escaped_word) { single_escaped | double_escaped }
      rule(:word) { (escaped_word | match(/\w|\./)).repeat(1) }
      rule(:list) { word >> (match(',') >> word).repeat(1) }

      rule(:short) { match('-') }
      rule(:long) { short >> short }
      rule(:neg_opt_prefix) { (long | short) >> (str('no-') | str('NO-')) >> word }
      rule(:opt_prefix) { (long | short) >> word }

      rule(:arg) { word >> space }
      rule(:opt) { opt_prefix.as(:key) >> separator.as(:sep) >> (list | word).as(:val) >> space }
      rule(:flag) { (neg_opt_prefix | opt_prefix) >> space }

      rule(:expression) { (opt.as(:opt) | flag.as(:flag) | arg.as(:arg)).repeat.as(:command_line) }

      root :expression
    end

    class ArgTransform < Parslet::Transform
      rule(:arg => simple(:arg_val)) { Rubycom::ArgParse.transform(:arg, arg_val) }
      rule(:opt => subtree(:opt)) { Rubycom::ArgParse.transform(:opt, opt) }
      rule(:flag => simple(:flag)) { Rubycom::ArgParse.transform(:flag, flag) }
      rule(:command_line => subtree(:line)) { Rubycom::ArgParse.transform(:command_line, line) }
    end

    def self.transform(key, val)
      case key
        when :arg
          val = Rubycom::ArgParse.transform_arg(val.str.strip)
        when :opt
          val = Rubycom::ArgParse.transform_opt(val)
        when :flag
          val = Rubycom::ArgParse.transform_flag(val.str.strip)
        when :command_line
          val = Rubycom::ArgParse.transform_command_line(val)
        else
          val = val.str.strip
      end
      {
          key => val
      }
    end

    def self.transform_arg(match_string)
      self.load_string(match_string)
    end

    def self.transform_opt(subtree)
      value = self.load_opt_value(subtree[:val].str.split(','))
      {
          subtree[:key].str.reverse.chomp('-').chomp('-').reverse => value
      }
    end

    def self.load_opt_value(value)
      (value.length == 1) ? self.load_string(value.first) : value.map { |v| self.load_string(v) }
    end

    def self.load_string(string)
      if string.start_with?('#') || string.start_with?('!')
        result = string
      else
        result = YAML.load(string.sub(/'|"/, '').reverse.sub(/'|"/, '').reverse)
      end
      result
    end

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
        }
      end
    end

    def self.transform_command_line(subtree)
      subtree.group_by { |hsh| hsh.keys.first }.map { |type, values|
        {
            "#{type}s".to_sym => values.map { |hsh|
              hsh[hsh.keys.first]
            }
        }
      }.reduce({}, &:merge).map{|type, values|
        case type
          when :opts
            {
                type => values.reduce({}){|acc, next_hsh|
                  if acc.has_key?(next_hsh.keys.first)
                    if acc[next_hsh.keys.first].class == Array
                      acc[next_hsh.keys.first] << next_hsh[next_hsh.keys.first]
                    else
                      acc[next_hsh.keys.first] = ([acc[next_hsh.keys.first]] << next_hsh[next_hsh.keys.first])
                    end
                  else
                    acc[next_hsh.keys.first] = next_hsh[next_hsh.keys.first]
                  end
                  acc
                }
            }
          when :flags
            {
                type => values.reduce({}, &:merge)
            }
          else
            {
                type => values
            }
        end
      }.reduce({}, &:merge)
    end

  end
end
