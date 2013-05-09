require "rubycom/version"
require 'yard'
require 'yaml'

module Rubycom

  # Detects that Rubycom was included in another module and calls Rubycom#run
  #
  # @param [Module] base the module which invoked 'include Rubycom'
  def self.included(base)
    base.module_eval { Rubycom.run(self, ARGV) }
  end

  def self.run(base, args=[])
    begin
      raise "Invalid base class invocation: #{base}" if base.nil?

      command = args[0] || nil
      arguments = args[1..-1] || []

      if command == 'help'
        help_topic = arguments[0]
        if help_topic.nil?
          puts self.get_summary(base)
        else
          puts self.get_command_usage(base, help_topic)
        end
      else
        self.run_command(base, command, arguments)
      end

    rescue Exception => e
      puts e
      puts self.get_summary(base)
    end
  end

  def self.run_command(base, command, arguments=[])
    raise 'No command specified.' if command.nil? || command.length == 0
    begin
      command_sym = command.to_sym
      valid_commands = self.get_commands(base)
      raise "Invalid Command: #{command}." unless valid_commands.include? command_sym
      method = base.public_method(command_sym)
      raise "No public singleton method found for symbol: #{command_sym}" if method.nil?
      params = self.parse_arguments(method.parameters, arguments)
      method.call(*params)
    rescue Exception => e
      puts e
      puts self.get_command_usage(base, command)
    end
  end

  def self.parse_arguments(parameters=[], arguments=[])
    parsed_params = {}
    args_l = arguments.length
    min_args_l = 0
    max_args_l = 0
    parameters.each { |type, sym|
      parsed_params[sym] = {type: type, val: nil}
      min_args_l += 1 if type == :req
      max_args_l += 1
    }
    raise "Wrong number of args expected #{min_args_l} to #{max_args_l}. Received: #{args_l}" unless (min_args_l<=args_l)&&(args_l<=max_args_l)
    parsed_req = []
    parsed_options = {}
    arguments.each { |arg|
      if arg[0] == '-'
        key, val = arg.split('=')
        parsed_options[key[1..-1].to_sym] = self.parse_arg(val)
      else
        parsed_req << self.parse_arg(arg)
      end
    }
    parsed_params.each_key { |key|
      param_type = parsed_params[key][:type]
      if (param_type == 'opt') || (param_type == :opt)
        parsed_options.each { |opt_key, opt_val|
          parsed_params[key][:val] = opt_val if opt_key == key
          parsed_options.delete(opt_key) if opt_key == key
        }
        parsed_params[key][:val] = parsed_req.shift if parsed_params[key][:val].nil?
      else
        parsed_params[key][:val] = parsed_req.shift
      end
    }
    ret_params = []
    parsed_params.each_key { |key|
      ret_params<< parsed_params[key][:val]
    }
    ret_params
  end

  def self.parse_arg(arg)
    return nil if arg.nil? || arg.length == 0
    val = YAML.load(arg) rescue nil
    val || "#{arg}"
  end

  def self.get_commands(base)
    base.singleton_methods(false)
  end

  def self.get_summary(base)
    return_str = ""
    base_singleton_methods = base.singleton_methods(false)
    return_str << "Commands:\n"unless base_singleton_methods.length == 0
    base_singleton_methods.each { |sym|
      return_str << "  " << self.get_command_summary(base, sym)
    }
    return_str
  end

  def self.get_usage(base)
    return_str = ""
    base_singleton_methods = base.singleton_methods(false)
    return_str << "Commands:\n" unless base_singleton_methods.length == 0
    base_singleton_methods.each { |sym|
      cmd_usage = self.get_command_usage(base, sym)
      return_str << "#{cmd_usage}\n" unless cmd_usage.nil? || cmd_usage.empty?
    }
    return_str
  end

  def self.get_command_summary(base, command_name)
    return 'No command specified.' if command_name.nil? || command_name.length == 0
    m = base.public_method(command_name.to_sym)
    method_doc = self.get_doc(m)
    desc = method_doc[:desc]
    (desc.nil?||desc=='nil') ? "#{m.name}\n" : "#{m.name} - #{desc}\n"
  end

  def self.get_command_usage(base, command_name)
    return 'No command specified.' if command_name.nil? || command_name.length == 0
    m = base.public_method(command_name.to_sym)
    optional_params = []
    required_params = []
    method_params = m.parameters || []
    method_params.each { |type, sym|
      if (type == :opt) || (type == 'opt')
        optional_params << sym
      else
        required_params << sym
      end
    }
    method_doc = self.get_doc(m)
    msg = "Command: #{m.name}\n"
    msg << "    Usage: #{m.name}"
    required_params.each { |param|
      msg << " #{param}"
    }
    msg << "\n" if (required_params.length != 0) && (optional_params.length == 0)
    msg << ' [' unless optional_params.length == 0
    optional_params.each_with_index { |option, index|
      if index == 0
        msg << "-#{option}=val"
      else
        msg << "|-#{option}=val"
      end
    }
    msg << "]\n" unless optional_params.length == 0
    msg << "    Parameters:\n" unless (required_params.length == 0) && (optional_params.length == 0)
    if method_doc[:params].respond_to?(:each)
      method_doc[:params].each { |param_doc|
        msg << "        #{param_doc.gsub('[', '').gsub(']', ' -')}\n"
      }
    else
      msg << "\n"
    end
    msg << "    Returns:\n"
    if method_doc[:return].respond_to?(:each)
      method_doc[:return].each{|return_doc|
        msg << "        #{return_doc}\n"
      }
    else
      msg << "        #{method_doc[:return]}\n" unless method_doc[:return].nil? || (method_doc[:return].length == 0)
    end
    msg
  end


  def self.get_doc(method)
    source_file = method.source_location.first
    doc_str = ''
    method_hash = {}
    YARD.parse_string(File.read(source_file)).enumerator.each { |sexp|
      method_hash = self.retrieve_method_hash(sexp, method) if method_hash.length == 0
      doc_str = method_hash[:method_doc] || 'nil'
    }
    doc_hash = {}
    doc_str.split("\n").each { |doc_line|
      if doc_line.match(/^(@param)/)
        param_doc = doc_line.gsub('@param ', '')
        params = doc_hash[:params]
        if params.nil? || params.length == 0
          params = [param_doc]
        else
          params << param_doc
        end
        doc_hash[:params] = params
      elsif doc_line.match(/^(@return)/)
        if doc_hash[:return].nil?
          doc_hash[:return] = doc_line.gsub('@return ', '')
        else
          doc_hash[:return] = [doc_hash[:return]]
          doc_hash[:return] << doc_line.gsub('@return ', '')
        end
      elsif doc_line.match(/^(@.+\s+)$/) == nil
        if doc_hash[:desc].nil?
          doc_hash[:desc] = doc_line unless doc_line.lstrip.length==0
        else
          doc_hash[:desc] << doc_line unless doc_line.lstrip.length==0
        end
      else
        if doc_hash[:extended].nil?
          doc_hash[:extended] = doc_line
        else
          doc_hash[:extended] << doc_line
        end

      end
    }
    if doc_hash[:return].nil?
      doc_hash[:return] = 'void'
    end
    doc_hash
  end

  @parser_dump = false

  def self.retrieve_method_hash(sexp_arr, method, level=0)
    tabs = ''
    level.times { tabs<<' ' } if @parser_dump
    return {} if (sexp_arr.nil? || sexp_arr.length == 0 || method.nil?)
    result_hash = {}
    sexp_arr.each { |sexp|
      if  !sexp.nil? && sexp.kind_of?(YARD::Parser::Ruby::AstNode)
        puts "#{tabs}------------parsing: #{sexp}------------------" if @parser_dump
        if (sexp.type == :defs) && (sexp.children[2].source == "#{method.name}")
          puts "#{tabs}Node.type=:defs and has child node #{sexp.children[2].source}, #{sexp}\n" if @parser_dump
          result_hash = {method_doc: sexp.docstring, method_sexp: sexp}
          puts "#{tabs}returning matched result_hash=#{result_hash}" if @parser_dump
          puts "#{tabs}---------------------------------------------------" if @parser_dump
          return result_hash
        else
          puts "#{tabs}Node.type not equal to  :defs or no child node matching #{method.name}, #{sexp}\n" if @parser_dump
          result_hash = self.retrieve_method_hash(sexp.children, method, level+=1) if result_hash.length == 0
          puts "#{tabs}result_hash set #{result_hash}" if (result_hash.length == 0) && @parser_dump
        end
      else
        puts "#{tabs}skipping: #{sexp}" if @parser_dump
      end
    }
    puts "#{tabs}returning result_hash=#{result_hash}" if @parser_dump
    puts "#{tabs}---------------------------------------------------" if @parser_dump
    result_hash
  end

end