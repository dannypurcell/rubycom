module Rubycom
  module YardDoc
    require 'yard'

    def self.document_commands(commands_hsh)
      commands = self.check(commands_hsh)
      commands.map { |base, com_hsh|
        {
            base => com_hsh.map{|com_sym,hsh|
              case hsh[:type]
                when :module
                  {
                      com_sym => hsh.merge({documentation: Rubycom::YardDoc.module_doc(com_sym, hsh[:source])})
                  }
                when :command
                  {
                      com_sym => hsh.merge({documentation: Rubycom::YardDoc.command_doc(com_sym, hsh[:source])})
                  }
                else
                  raise "DocumentationError: Unrecognized command type #{type} for #{com_sym}"
              end
            }.reduce({},&:merge)
        }
      }.reduce({},&:merge)
    end

    def self.check(sourced_commands)
      raise "commands should be a Hash but was #{sourced_commands.class}" unless sourced_commands.class == Hash
      sourced_commands.each{|_, cmd_hsh|
        raise "commands value should be a Hash but was #{cmd_hsh.class}" unless cmd_hsh.class == Hash
        cmd_hsh.each{|com_sym,hsh|
          raise "command key should be a Symbol or String but has #{com_sym}" unless [Symbol,String].include?(com_sym.class)
          raise "command value should have key :type but has #{hsh.keys}" unless hsh.has_key?(:type)
          raise "command value should have key :source but has #{hsh.keys}" unless hsh.has_key?(:source)
        }
      }
      sourced_commands
    end

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
            self.command_doc(doc_method.name, doc_method, true)
          }
      }
    end

    def self.command_doc(method_name, module_source_obj, summary=false)
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
      if summary
        {
            name: doc_obj.name,
            type: doc_obj.type,
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
            }
        }
      else
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
            }
        }
      end
    end

  end
end
