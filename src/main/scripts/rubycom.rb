require 'yard'
module Rubycom

  def self.included(base)

    base_singleton_methods = base.singleton_methods(false)
    puts "BaseClass: #{base}"
    puts "Public/ProtectedStaticMethods:"
    base_singleton_methods.each { |sym|
      m = base.public_method(sym)
      req_params=[]
      optional_params=[]
      m.parameters.each { |opt_req, symbol|
        req_params<<symbol if opt_req==:req
        optional_params<<symbol if opt_req==:opt
      }
      msg = "Usage: #{m.name} [option]"
      req_params.each { |param|
        msg << " #{param}"
      }
      msg<<"\n"
      optional_params.each { |option|
        msg<<"\t -#{option}\n"
      }
      msg << "Source: #{m.name}\n"
      msg << self.get_doc(m)
      puts msg
    }
  end

  def self.get_doc(method)
    source_file = method.source_location.first
    doc_str = ""
    YARD.parse_string(File.read(source_file)).enumerator.each{|sexp|
      method_hash = Rubycom.retrieve_method_hash(sexp,method)
      doc_str = method_hash.to_s#method_hash[:doc] || "nil"
    }
    doc_str
  end

  def self.retrieve_method_hash(sexp_arr, method)
    return {} if (sexp_arr.nil? || sexp_arr.length == 0)
    result_list = []
    sexp_arr.each{|sexp|
      puts "#{sexp.docstring}"
      if (sexp.children[2].source.include? "#{method.name}") && (sexp.type == :defs)
        params_hash = {}
        sexp.jump(:params).children.each{ |param_sexp|

        }
        result_list << { method_desc:sexp.docstring, param_desc:}
      else
        result_list << Rubycom.retrieve_method_hash(sexp.children,method)
      end
    }
    return_list = []
    result_list.each{ |result|
      unless result.nil? || result.length == 0
        return_list << result
      end
    }
    return_list
  end

end