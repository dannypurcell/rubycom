require 'yard'
module Rubycom
  module YardDoc

    def self.module_doc(module_name, module_source)
      YARD::Registry.clear
      YARD.parse_string(module_source.to_s)
      doc_obj = YARD::Registry.at(module_name.to_s)
      return {short_doc: '', full_doc: ''} if doc_obj.nil?
      {
          module_name: doc_obj.name,
          type: doc_obj.type,
          path: doc_obj.path,
          visibility: doc_obj.visibility,
          short_doc: doc_obj.docstring.summary,
          full_doc: doc_obj.docstring.to_s,
          commands: doc_obj.children.map { |doc_method|
            self.command_doc(doc_method.name, doc_method)
          },
          source: doc_obj.source
      }
    end

    def self.command_doc(method_name, module_source_obj)
      if module_source_obj.class == YARD::CodeObjects::MethodObject
        doc_obj = module_source_obj
      elsif module_source_obj.class == String
        YARD::Registry.clear
        YARD.parse_string(module_source_obj.to_s)
        method_name = method_name.name if method_name.class == Method
        doc_obj = YARD::Registry.at(method_name.to_s)
        doc_obj = YARD::Registry.at("::#{method_name.to_s}") if doc_obj.nil?
        doc_obj = YARD::Registry.at(method_name.to_s.split('.').last) if doc_obj.nil?
        raise "No such method #{method_name} in the given source." if doc_obj.nil?
      else
        raise "module_source_obj expected String or YARD::CodeObjects::MethodObject but was #{module_source_obj.class}"
      end
      {
          title: doc_obj.title,
          name: doc_obj.name,
          scope: doc_obj.scope,
          type: doc_obj.type,
          path: doc_obj.path,
          signature: doc_obj.signature,
          visibility: doc_obj.visibility,
          parameters: doc_obj.parameters.map{|k,v|
            # YARD's parsing returns pairs of params and values
            # if the param has a default value then the value is wrapped in a string
            # required arguments have a value of nil
            {
                param_name: k,
                required: v.nil?,
                default: (v.nil?)? nil : eval(v),
                doc_type: doc_obj.tags.select{|tag|tag.name == k.to_s}.map{|tag| tag.types }.join(','),
                doc: doc_obj.tags.select{|tag|tag.name == k.to_s}.map{|tag| tag.text}.join("\n")
            }
          },
          short_doc: doc_obj.base_docstring.summary,
          full_doc: doc_obj.base_docstring.to_s,
          tags: doc_obj.tags.map{|tag|
            {
                tag_name: tag.tag_name,
                name: tag.name,
                types: tag.types,
                text: tag.text
            }
          },
          source: doc_obj.source
      }
    end

  end
end
