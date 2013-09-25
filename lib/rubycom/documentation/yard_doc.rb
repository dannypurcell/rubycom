require 'yard'
module Rubycom
  module Documentation
    module YardDoc

      def self.module_doc(module_name, module_source)
        YARD::Registry.clear
        YARD.parse_string(module_source.to_s)
        doc_obj = YARD::Registry.at(module_name.to_s)
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
          doc_obj = YARD::Registry.at(method_name.to_s)
        else
          raise "module_source_obj must be a String or YARD::CodeObjects::MethodObject"
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
                  default: (v.nil?)? nil : eval(v)
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
end
