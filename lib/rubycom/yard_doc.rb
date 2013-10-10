module Rubycom
  module YardDoc
    require 'yard'

    def self.document_commands(commands_hsh)
      commands = self.check(commands_hsh)
      self.map_doc(commands)
    end

    def self.check(sourced_commands)
      raise "#{sourced_commands} should be an Array but was #{sourced_commands.class}" unless sourced_commands.class == Array
      sourced_commands.each { |cmd_hsh|
        raise "#{cmd_hsh} should be a Hash but was #{cmd_hsh.class}" unless cmd_hsh.class == Hash
        raise "#{cmd_hsh} should have keys :command and :source" unless (cmd_hsh.keys - [:command, :source]).size >= 0
      }
      sourced_commands
    end

    def self.map_doc(commands)
      commands.map { |cmd_hsh|
        {
            command: cmd_hsh[:command],
            doc: if cmd_hsh[:command].class == Module
                   self.module_doc(cmd_hsh[:command].to_s, cmd_hsh[:source])
                 elsif cmd_hsh[:command].class == Method
                   self.method_doc(cmd_hsh[:command].name, cmd_hsh[:source])
                 else
                   {short_doc: '', full_doc: ''}
                 end
        }
      }
    end

    def self.module_doc(module_name, module_source)
      YARD::Registry.clear
      YARD.parse_string(module_source.to_s)
      doc_obj = YARD::Registry.at(module_name.to_s)
      return {short_doc: '', full_doc: ''} if doc_obj.nil?
      {
          short_doc: doc_obj.docstring.summary,
          full_doc: doc_obj.docstring.to_s,
          sub_command_docs: doc_obj.children.map { |doc_method|
            {
                doc_method.name => self.method_doc(doc_method.name, doc_method)[:short_doc]
            }
          }.reduce({},&:merge)
      }
    end

    def self.method_doc(method_name, module_source_obj)
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
          parameters: doc_obj.parameters.map { |k, v|
            # YARD's parsing returns pairs of params and values
            # if the param has a default value then the value is wrapped in a string
            # required arguments have a value of nil
            {
                param_name: k,
                required: v.nil?,
                default: (v.nil?) ? nil : eval(v),
                doc_type: doc_obj.tags.select { |tag| tag.name == k.to_s }.map { |tag| tag.types }.join(','),
                doc: doc_obj.tags.select { |tag| tag.name == k.to_s }.map { |tag| tag.text }.join("\n")
            }
          },
          short_doc: doc_obj.base_docstring.summary,
          full_doc: doc_obj.base_docstring.to_s,
          tags: doc_obj.tags.map { |tag|
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
