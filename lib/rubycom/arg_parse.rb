require 'parslet'
require 'yaml'

module Rubycom
  module ArgParse

    class ArgParseError < StandardError;
    end

    class ArgParser < Parslet::Parser
      rule(:space) { match('\s').repeat(1) }
      rule(:eq) { match('=') }
      rule(:separator) { (eq | (space >> eq >> space) | space) }

      rule(:word) { match('\w').repeat(1) }
      rule(:list) { word >> (match(',') >> word).repeat(1) }

      rule(:short) { match('-') }
      rule(:long) { short >> short }
      rule(:neg_opt_prefix) { (long | short) >> (str('no-') | str('NO-')) >> word }
      rule(:opt_prefix) { (long | short) >> word }

      rule(:arg) { word >> space }
      rule(:opt) { opt_prefix >> separator >> (list | word) >> space }
      rule(:flag) { (neg_opt_prefix | opt_prefix) >> space }

      rule(:expression) { (arg.as(:arg) | opt.as(:opt) | flag.as(:flag)).repeat }

      root :expression
    end

    def self.parse(*args)
      args = self.check(args)
      arg_string = args.join(' ') << ' '
      begin
        self.validate(
            self.organize(
                self.clean(
                    ArgParser.new.parse(arg_string)
                )
            )
        )
      rescue Parslet::ParseFailed => failure
        puts failure.cause.ascii_tree
      end
    end

    def self.check(*args)
      raise "args should be an array of Strings" if args.map { |arg| arg.class }.uniq.length > 1
      args
    end

    def self.clean(parsed_result)
      parsed_result.group_by { |hsh|
        hsh.keys.first
      }.map { |type, arr|
        {
            type => arr.map { |hsh| hsh.values.first.str.strip }
        }
      }.reduce({}, &:merge)
    end

    def self.organize(clean_parsed_result)
      clean_parsed_result.map { |type, matches|
        case type
          when :opt
            {
                "#{type.to_s}s".to_sym => self.organize_options(matches)
            }
          when :flag
            {
                "#{type.to_s}s".to_sym => self.organize_flags(matches)
            }
          else
            {
                "#{type.to_s}s".to_sym => matches
            }
        end
      }.reduce({}, &:merge)
    end

    def self.organize_options(option_matches)
      option_matches.map { |match_str|
        key, val = match_str.split(/\s|\=/)
        {
            key.reverse.chomp('-').chomp('-').reverse => val
        }
      }.group_by { |hsh| hsh.keys.first }.reduce({}) { |acc, nex|
        k, v = nex
        acc[k] = v.map { |hsh| hsh.values.first.split(',') }.flatten
        acc
      }
    end

    def self.organize_flags(flag_matches)
      flag_matches.map { |match_string|
        self.organize_flag(match_string)
      }.group_by{|hsh|hsh.keys.first}.map{|sub_type,arr|
        {
            sub_type => arr.map{|hsh|
              hsh.values.first
            }.flatten
        }
      }.reduce({},&:merge)
    end

    def self.organize_flag(match_string)
      if match_string.start_with?('--')
        long_flag = match_string.reverse.chomp('-').chomp('-').reverse
        long_flag_key = long_flag.sub(/no-|NO-/,'')
        long_flag_val = (long_flag.start_with?('no-')||long_flag.start_with?('NO-')) ? false : true
        {
            longs: {
                long_flag_key => long_flag_val
            }
        }
      else
        short_flag = match_string.reverse.chomp('-').reverse
        short_flag_key = short_flag.sub(/no-|NO-/,'')
        short_flag_val = (short_flag.start_with?('no-')||short_flag.start_with?('NO-')) ? false : true
        {
            shorts: short_flag_key.split(//).map{|k|
              {
                  k => short_flag_val
              }
            }
        }
      end
    end

    def self.validate(organized_result)
      organized_result[:flags].each{|type,arr|
        arr.group_by{|hsh|hsh.keys.first}.each{|k,v|
          raise ArgParseError, "Duplicate #{type.to_s.chomp('s')} flag: #{k} has multiple values #{v}" if v.length > 1
        }
      }
      organized_result
    end

  end
end
