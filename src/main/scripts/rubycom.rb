require 'yard'
require 'time'
require 'yaml'

module Rubycom
  @filter_methods = []

  def self.included(base)
    base.module_eval { Rubycom.run(self, ARGV) }
  end

  def self.run(base, args=[])
    begin
      raise "Invalid base class invocation: #{base}" if base.nil?
      command = args[0] || nil
      arguments = args[1..-1] || []

      self.run_command(base, command, arguments)
    rescue Exception => e
      puts e
      puts self.get_usage(base)
    end
  end

  def self.run_command(base, command, arguments=[])
    raise "No command specified." if command.nil? || command.length == 0
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
      if (param_type == "opt") || (param_type == :opt)
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
    parsed_params.each_key{|key|
      ret_params<< parsed_params[key][:val]
    }
    ret_params
  end

  def self.parse_arg(arg)
    return nil if arg.nil? || arg.length == 0
    val = (Integer(arg) rescue Float(arg) rescue Time.parse(arg) rescue nil)
    val = (YAML::load(arg) rescue nil || arg) if val.nil?
    val || "#{arg}"
  end

  def self.get_commands(base)
    base.singleton_methods(false).select { |sym| !@filter_methods.include? sym }
  end

  def self.get_summary(base)
    return_str = "Commands:\n"
    base_singleton_methods = base.singleton_methods(false).select { |sym| !@filter_methods.include? sym }
    base_singleton_methods.each { |sym|
      return_str << self.get_command_summary(base,sym)
    }
    return_str
  end

  def self.get_usage(base)
    return_str = "Commands:\n"
    base_singleton_methods = base.singleton_methods(false).select { |sym| !@filter_methods.include? sym }
    base_singleton_methods.each { |sym|
      return_str << self.get_command_usage(base,sym)
    }
    return_str
  end

  def self.get_command_summary(base, command_name)
    m = base.public_method(command_name.to_sym)
    method_doc = self.get_doc(m)
    "#{m.name} - #{method_doc[:desc]}\n"
  end

  def self.get_command_usage(base, command_name)
    m = base.public_method(command_name.to_sym)
    optional_params = []
    required_params = []
    method_params = m.parameters || []
    method_params.each{ |type,sym|
      if (type == :opt) || (type == 'opt')
        optional_params << sym
      else
        required_params << sym
      end
    }
    method_doc = self.get_doc(m)
    msg = "\tUsage: #{m.name}"
    required_params.each { |param|
      msg << " #{param}"
    }
    msg << " [" unless optional_params.length == 0
    optional_params.each_with_index { |option, index|
      if index == 0
        msg << "-#{option}=val"
      else
        msg << "|-#{option}=val"
      end
    }
    msg << "]\n" unless optional_params.length == 0
    msg << "\tParameters:\n" unless (required_params.length == 0) && (optional_params.length == 0)
    if method_doc[:params].respond_to?(:each)
      method_doc[:params].each { |param_doc|
        msg << "\t\t#{param_doc.gsub("[", "").gsub("]", " -")}\n"
      }
    else
      msg << "\n"
    end
    msg << "\tReturns: #{method_doc[:return]}\n"
  end


  def self.get_doc(method)
    source_file = method.source_location.first
    doc_str = ""
    YARD.parse_string(File.read(source_file)).enumerator.each { |sexp|
      method_hash = self.retrieve_method_hash(sexp, method)
      doc_str = method_hash[:method_doc] || "nil"
    }
    doc_hash = {}
    doc_str.split("\n").each { |doc_line|
      if doc_line.include? "@param"
        param_doc = doc_line.gsub("@param", "").lstrip
        params = doc_hash[:params]
        if params.nil? || params.length == 0
          params = [param_doc]
        else
          params << param_doc
        end
        doc_hash[:params] = params
      elsif doc_line.include? "@return"
        doc_hash[:return] = doc_line.gsub("@return", "")
      else
        doc_hash[:desc] = doc_line unless doc_line.lstrip.length==0
      end
    }
    if doc_hash[:return].nil?
      doc_hash[:return] = "void"
    end
    doc_hash
  end

  def self.retrieve_method_hash(sexp_arr, method)
    return {} if (sexp_arr.nil? || sexp_arr.length == 0)
    result_hash = {}
    sexp_arr.each { |sexp|
      if (sexp.type == :defs) && (sexp.children[2].source.include? "#{method.name}")
        result_hash = {method_doc: sexp.docstring, method_sexp: sexp}
      else
        result_hash = self.retrieve_method_hash(sexp.children, method) if result_hash.length == 0
      end
    }
    result_hash
  end

end