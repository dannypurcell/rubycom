module Rubycom
  module YardDoc
    require 'yard'

    def self.document_command(command, source_plugin)
      self.document_commands([command], source_plugin).first[:doc]
    end

    def self.document_commands(commands, source_plugin)
      commands, source_plugin = self.check(commands, source_plugin)
      self.map_doc(commands, source_plugin)
    end

    def self.check(commands, source_plugin)
      YARD::Logger.instance.level = YARD::Logger::FATAL
      raise ArgumentError, "#{source_plugin} should be a Module but was #{source_plugin.class}" unless source_plugin.class == Module
      raise ArgumentError, "#{commands} should be an Array but was #{commands.class}" unless commands.class == Array
      [commands, source_plugin]
    end

    def self.map_doc(commands, source_plugin)
      commands.map { |cmd|
        {
            command: cmd,
            doc: if cmd.class == Module
                   self.module_doc(cmd, source_plugin)
                 elsif cmd.class == Method
                   self.method_doc(cmd, source_plugin)
                 else
                   {short_doc: '', full_doc: ''}
                 end
        }
      }
    end

    def self.module_doc(mod, source_plugin)
      module_source = source_plugin.source_command(mod)
      YARD::Registry.clear
      YARD.parse_string(module_source.to_s)
      doc_obj = YARD::Registry.at(mod.to_s)
      return {short_doc: '', full_doc: ''} if doc_obj.nil?
      {
          short_doc: doc_obj.docstring.summary,
          full_doc: doc_obj.docstring.to_s,
          sub_command_docs: doc_obj.meths(:visibility => :public, :scope => :class).map { |doc_method|
            {
                doc_method.name => self.method_doc(mod.public_method(doc_method.name), doc_method)[:short_doc]
            }
          }.reduce({}, &:merge).merge(
              doc_obj.mixins.select { |doc_mod| doc_mod.name != :Rubycom }.map { |doc_mod|
                YARD.parse_string(source_plugin.source_command(Kernel.const_get(doc_mod.name)))
                sub_doc_obj = YARD::Registry.at(doc_mod.to_s)
                {
                    doc_mod.name => (sub_doc_obj.nil?) ? '' : sub_doc_obj.docstring.summary
                }
              }.reduce({}, &:merge)
          )
      }
    end

    def self.method_doc(method, source_plugin)
      raise ArgumentError, "method should be a Method but was #{method.class}" unless method.class == Method
      method_param_types = method.parameters.map { |type, sym| {sym => type} }.reduce({}, &:merge)
      if source_plugin.class == YARD::CodeObjects::MethodObject
        doc_obj = source_plugin
      elsif source_plugin.class == Module
        YARD::Registry.clear
        YARD.parse_string(source_plugin.source_command(method))
        method = method.name if method.class == Method
        doc_obj = YARD::Registry.at(method.to_s)
        doc_obj = YARD::Registry.at("::#{method.to_s}") if doc_obj.nil?
        doc_obj = YARD::Registry.at(method.to_s.split('.').last) if doc_obj.nil?
        raise ArgumentError, "No such method #{method} in the given source." if doc_obj.nil?
      else
        raise ArgumentError, "source_plugin should be YARD::CodeObjects::MethodObject|Module but was #{source_plugin.class}"
      end
      {
          parameters: doc_obj.parameters.map { |k, v|
            # YARD's parsing returns pairs of params and values
            # if the param has a default value then the value is wrapped in a string
            # required arguments have a value of nil
            param_type = method_param_types[k.reverse.chomp('*').reverse.to_sym]
            param_default = if param_type == :rest
                              []
                            else
                              (v.class == String) ? eval(v) : v
                            end
            {
                param_name: k,
                type: param_type,
                default: param_default,
                doc_type: doc_obj.tags.select { |tag| tag.name == k.to_s }.map { |tag| tag.types }.join(','),
                doc: doc_obj.tags.select { |tag| tag.name == k.to_s }.map { |tag| tag.text }.join("\n")
            }
          },
          short_doc: doc_obj.base_docstring.summary.to_s,
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
