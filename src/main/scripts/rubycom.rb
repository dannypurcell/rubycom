require 'yard'
module Rubycom

  def self.included(base)
    puts "BaseClass: #{base}"
    puts "Public/ProtectedStaticMethods:"
    puts Rubycom.get_usage(base,true)
  end

  def self.get_usage(base, print_extended=false)
    return_str = ""
    base_singleton_methods = base.singleton_methods(false)
    base_singleton_methods.each { |sym|
      m = base.public_method(sym)
      method_doc = self.get_doc(m)
      req_params=[]
      optional_params=[]
      m.parameters.each { |opt_req, symbol|
        req_params<<symbol if opt_req==:req
        optional_params<<symbol if opt_req==:opt
      }
      msg = "#{m.name} -\t#{method_doc[:desc]}\n"
      extended_msg = "Usage: #{m.name}"
      req_params.each { |param|
        extended_msg << " #{param}"
      }
      extended_msg << " ["
      optional_params.each_with_index { |option,index|
        if index == 0
          extended_msg << "#{option}"
        else
          extended_msg << "|#{option}"
        end
      }
      extended_msg << "]\n"
      extended_msg << "Parameters:\n"
      method_doc[:params].each{ |param_doc|
        extended_msg << "\t#{param_doc.gsub("[","").gsub("]"," -")}\n"
      }
      extended_msg << "Returns: #{method_doc[:return]}\n"
      if print_extended
        return_str << "#{msg}"
        return_str << "#{extended_msg}\n"
      else
        return_str << msg
      end
    }
    return_str
  end

  def self.get_doc(method)
    source_file = method.source_location.first
    doc_str = ""
    YARD.parse_string(File.read(source_file)).enumerator.each{|sexp|
      method_hash = Rubycom.retrieve_method_hash(sexp,method)
      doc_str = method_hash[:method_doc] || "nil"
    }
    doc_hash = {}
    doc_str.split("\n").each{|doc_line|
      if doc_line.include?"@param"
        param_doc = doc_line.gsub("@param","").lstrip
        params = doc_hash[:params]
        if params.nil? || params.length == 0
          params = [param_doc]
        else
          params << param_doc
        end
        doc_hash[:params] = params
      elsif doc_line.include?"@return"
        doc_hash[:return] = doc_line.gsub("@return","")
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
    sexp_arr.each{|sexp|
      if (sexp.type == :defs) && (sexp.children[2].source.include? "#{method.name}")
        result_hash = { method_doc:sexp.docstring, method_sexp: sexp }
      else
        result_hash = Rubycom.retrieve_method_hash(sexp.children,method) if result_hash.length == 0
      end
    }
    result_hash
  end

end