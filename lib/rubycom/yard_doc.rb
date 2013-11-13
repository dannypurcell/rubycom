module Rubycom
  module YardDoc
    require 'yard'

    # Transforms the command to a Hash representing the command and it's documentation
    #
    # @param [Array] command a Module or Method to be documented
    # @param [Module] source_method a Module which will be used to retrieve module and method source code
    # @return [Array] a Hash which is the result calling #map_doc
    def self.document_command(command, source_method)
      self.document_commands([command], source_method).first[:doc]
    end

    # Transforms each command in commands to a Hash representing the command and it's documentation
    #
    # @param [Array] commands a set of Modules and Methods to be documented
    # @param [Module] source_method a Module which will be used to retrieve module and method source code
    # @return [Array] a set of Hashes which are the result calling #map_doc
    def self.document_commands(commands, source_method)
      commands, source_method = self.check(commands, source_method)
      self.map_doc(commands, source_method)
    end

    # Provides upfront checking for this inputs to #document_commands
    def self.check(commands, source_fn)
      YARD::Logger.instance.level = YARD::Logger::FATAL
      raise ArgumentError, "#{source_fn} should be a Method or Proc but was #{source_fn.class}" unless [Method, Proc].include?(source_fn.class)
      raise ArgumentError, "#{commands} should be an Array but was #{commands.class}" unless commands.class == Array
      [commands, source_fn]
    end

    # Transforms each command in commands to a Hash representing the command and it's documentation
    #
    # @param [Array] commands a set of Modules and Methods to be documented
    # @param [Method|Proc] source_method used to retrieve module and method source code
    # @return [Array] a set of Hashes which are the result of calls to #module_doc and #method_doc
    def self.map_doc(commands, source_method)
      commands.map { |cmd|
        {
            command: cmd,
            doc: if cmd.class == Module
                   self.module_doc(cmd, source_method)
                 elsif cmd.class == Method
                   self.method_doc(cmd, source_method)
                 else
                   {short_doc: '', full_doc: ''}
                 end
        }
      }
    end

    # Extracts elements of source code documentation for the given module. Calls #source_command on the given
    # source_plugin to retrieve the method's source code.
    #
    # @param [Module] mod a Module instance representing the module whose documentation should be parsed
    # @param [Method] source_method a Module which will be used to retrieve module and method source code
    # @return [Hash] :short_doc => String, :full_doc => String, :sub_command_docs => [ { sub_command_name_symbol => String } ]
    def self.module_doc(mod, source_method)
      module_source = source_method.call(mod)
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
                YARD.parse_string(source_method.call(doc_mod.name).to_s)
                sub_doc_obj = YARD::Registry.at(doc_mod.to_s)
                {
                    doc_mod.name => (sub_doc_obj.nil?) ? '' : sub_doc_obj.docstring.summary.to_s
                }
              }.reduce({}, &:merge)
          )
      }
    end

    # Extracts elements of source code documentation for the given method. Calls #source_command on the given source_plugin
    # to retrieve the method's source code.
    #
    # @param [Method] method a Method instance representing the method whose documentation should be parsed
    # @param [Method|Proc|YARD::CodeObjects::MethodObject] source_method called to retrieve the method's source code.
    # Alternately this parameter can be a YARD::CodeObjects::MethodObject which will be used instead of looking
    # up the method's source code
    # @return [Hash] :short_doc => String, :full_doc => String,
    # :tags => [ { :tag_name => String, :name => String, :types => [String], :text => String  } ],
    # :parameters => [ { :param_name => String, :type => :req|:opt|:rest, :default => Object, :doc_type => String, :doc => String } ]
    def self.method_doc(method, source_method)
      raise ArgumentError, "method should be a Method but was #{method.class}" unless method.class == Method
      method_param_types = method.parameters.map { |type, sym| {sym => type} }.reduce({}, &:merge)
      if source_method.class == YARD::CodeObjects::MethodObject
        doc_obj = source_method
      elsif source_method.is_a?(Proc) || source_method.is_a?(Method)
        YARD::Registry.clear
        YARD.parse_string(source_method.call(method))
        method_name = method.name
        doc_obj = YARD::Registry.at(method_name.to_s)
        doc_obj = YARD::Registry.at("::#{method_name.to_s}") if doc_obj.nil?
        doc_obj = YARD::Registry.at("\##{method_name.to_s}") if doc_obj.nil?
        doc_obj = YARD::Registry.at(method_name.to_s.split('.').last) if doc_obj.nil?
        raise ArgumentError, "No such method #{method_name} in the given source." if doc_obj.nil?
      else
        raise ArgumentError, "source_plugin should be YARD::CodeObjects::MethodObject|Method but was #{source_method.class}"
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
                              (v.class == String) ? method.receiver.module_eval(v) : v
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
