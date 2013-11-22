require "#{File.dirname(__FILE__)}/../../lib/rubycom/yard_doc.rb"

require "#{File.dirname(__FILE__)}/../../lib/rubycom/sources.rb"
require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class YardDocTest < Test::Unit::TestCase

  def test_document_commands
    test_commands = [
        UtilTestComposite,
        UtilTestModule,
        UtilTestModule.public_method(:test_command),
        "test_extra_arg"
    ]
    test_source_fn = Rubycom::Sources.public_method(:source_command)
    result = Rubycom::YardDoc.document_commands(test_commands, test_source_fn)
    assert(result.class == Array, "result should be an array")
    result.each{|h|
      assert(h.class == Hash, "each command in the result should be a Hash. #{h}")
      assert(h.has_key?(:command), "each command hash should respond to :command. #{h}")
      assert([Module, Method, String].include?(h[:command].class),"each command should be a Module | Method | String. #{h[:command]}")
      assert(h.has_key?(:doc), "each command hash should respond to :doc. #{h}")
      assert(h[:doc].has_key?(:full_doc), "each doc hash should respond to :full_doc. #{h[:doc]}")
      assert(h[:doc].has_key?(:short_doc), "each doc hash should respond to :short_doc. #{h[:doc]}")
      if h[:command].class == Module
        assert(h[:doc].has_key?(:sub_command_docs), "if the command is a module then the :doc has should respond to :sub_command_docs #{h[:doc]}")
        assert(h[:doc][:sub_command_docs].class == Hash, "sub_command_docs should be a Hash. #{h[:doc][:sub_command_docs]}")
        h[:doc][:sub_command_docs].each{|k,v|
          assert(k.class == Symbol, "each sub_command_doc key should be a symbol. k: #{k}, k.class #{k.class}")
          assert(v.class == String, "each sub_command_doc value should be a string. k: #{k}, v: #{v}, v.class: #{v.class}")
        }
      elsif h[:command].class == Method
        assert(h[:doc].has_key?(:parameters), "if the command is a method then the :doc has should respond to :parameters. #{h[:doc]}")
        assert(h[:doc].has_key?(:tags), "if the command is a method then the :doc has should respond to :tags. #{h[:doc]}")
        assert(h[:doc][:parameters].class == Array, "parameters should be a Hash. #{h[:doc][:parameters]}")
        assert(h[:doc][:tags].class == Array, "parameters should be a Hash. #{h[:doc][:tags]}")
        h[:doc][:parameters].each{|ph|
          assert(ph.class == Hash, "each parameter should be a Hash. #{ph}")
          assert(ph.class == Hash, "each parameter should be a Hash. #{ph}")
          assert(ph.has_key?(:default), "each parameter should respond to :default. #{ph}")
          assert(ph.has_key?(:doc), "each parameter should respond to :doc. #{ph}")
          assert(ph.has_key?(:doc_type), "each parameter should respond to :doc_type. #{ph}")
          assert(ph.has_key?(:type), "each parameter should respond to :type. #{ph}")
        }
        h[:doc][:tags].each{|th|
          assert(th.class == Hash, "each tag should be a Hash")
          assert(th.has_key?(:name), "each tag should respond to :name. #{th}")
          assert(th.has_key?(:tag_name), "each tag should respond to :tag_name. #{th}")
          assert(th.has_key?(:text), "each tag should respond to :text. #{th}")
          assert(th.has_key?(:types), "each tag should respond to :types. #{th}")
        }
      else
        assert(([:full_doc, :short_doc] - h[:doc].keys).length == 0, "if the command is a String then :doc should only respond to :short_doc and :full_doc. #{h[:doc]}")
      end
    }
  end

  def test_document_command_command_run
    test_command = UtilTestModule.public_method(:test_command_with_return)
    test_source_fn = Rubycom::Sources.public_method(:source_command)
    result = Rubycom::YardDoc.document_command(test_command, test_source_fn)
    assert(result.has_key?(:full_doc), "each doc hash should respond to :full_doc. #{result}")
    assert(result.has_key?(:short_doc), "each doc hash should respond to :short_doc. #{result}")
    assert(result.has_key?(:parameters), "if the command is a method then the :doc has should respond to :parameters. #{result}")
    assert(result.has_key?(:tags), "if the command is a method then the :doc has should respond to :tags. #{result}")
    assert(result[:parameters].class == Array, "parameters should be a Hash. #{result[:parameters]}")
    assert(result[:tags].class == Array, "parameters should be a Hash. #{result[:tags]}")
    result[:parameters].each{|ph|
      assert(ph.class == Hash, "each parameter should be a Hash. #{ph}")
      assert(ph.has_key?(:default), "each parameter should respond to :default. #{ph}")
      assert(ph.has_key?(:doc), "each parameter should respond to :doc. #{ph}")
      assert(ph.has_key?(:doc_type), "each parameter should respond to :doc_type. #{ph}")
      assert(ph.has_key?(:type), "each parameter should respond to :type. #{ph}")
    }
    result[:tags].each{|th|
      assert(th.class == Hash, "each tag should be a Hash")
      assert(th.has_key?(:name), "each tag should respond to :name. #{th}")
      assert(th.has_key?(:tag_name), "each tag should respond to :tag_name. #{th}")
      assert(th.has_key?(:text), "each tag should respond to :text. #{th}")
      assert(th.has_key?(:types), "each tag should respond to :types. #{th}")
    }
  end

  def test_document_command_command_run_rest
    test_command = UtilTestModule.public_method(:test_command_mixed_options)
    test_source_fn = Rubycom::Sources.public_method(:source_command)
    result = Rubycom::YardDoc.document_command(test_command, test_source_fn)
    assert(result.has_key?(:full_doc), "each doc hash should respond to :full_doc. #{result}")
    assert(result.has_key?(:short_doc), "each doc hash should respond to :short_doc. #{result}")
    assert(result.has_key?(:parameters), "if the command is a method then the :doc has should respond to :parameters. #{result}")
    assert(result.has_key?(:tags), "if the command is a method then the :doc has should respond to :tags. #{result}")
    assert(result[:parameters].class == Array, "parameters should be a Hash. #{result[:parameters]}")
    assert(result[:tags].class == Array, "parameters should be a Hash. #{result[:tags]}")
    result[:parameters].each{|ph|
      assert(ph.class == Hash, "each parameter should be a Hash. #{ph}")
      assert(ph.has_key?(:default), "each parameter should respond to :default. #{ph}")
      assert(ph.has_key?(:doc), "each parameter should respond to :doc. #{ph}")
      assert(ph.has_key?(:doc_type), "each parameter should respond to :doc_type. #{ph}")
      assert(ph.has_key?(:type), "each parameter should respond to :type. #{ph}")
      if ph[:type] == :rest
        assert(ph[:param_name].start_with?("*"), "a rest parameter's name should start with a star")
      end
    }
    result[:tags].each{|th|
      assert(th.class == Hash, "each tag should be a Hash")
      assert(th.has_key?(:name), "each tag should respond to :name. #{th}")
      assert(th.has_key?(:tag_name), "each tag should respond to :tag_name. #{th}")
      assert(th.has_key?(:text), "each tag should respond to :text. #{th}")
      assert(th.has_key?(:types), "each tag should respond to :types. #{th}")
    }
  end

  def test_document_command_run_module
    test_command = UtilTestModule
    test_source_fn = Rubycom::Sources.public_method(:source_command)
    result = Rubycom::YardDoc.document_command(test_command, test_source_fn)
    assert(result.has_key?(:sub_command_docs), "if the command is a module then the :doc has should respond to :sub_command_docs #{result}")
    assert(result[:sub_command_docs].class == Hash, "sub_command_docs should be a Hash. #{result[:sub_command_docs]}")
    result[:sub_command_docs].each{|k,v|
      assert(k.class == Symbol, "each sub_command_doc key should be a symbol. k: #{k}, k.class #{k.class}")
      assert(v.class == String, "each sub_command_doc value should be a string. k: #{k}, v: #{v}, v.class: #{v.class}")
    }
  end

  def test_document_command_run_composite
    test_command = UtilTestComposite
    test_source_fn = Rubycom::Sources.public_method(:source_command)
    result = Rubycom::YardDoc.document_command(test_command, test_source_fn)
    result_sub_command_doc = result[:sub_command_docs]
    result_sub_command_doc_keys = result_sub_command_doc.keys.map{|sub_mod|sub_mod.to_s}
    test_command.included_modules.reject{|mod|mod.to_s=="Rubycom"}.map{|mod|mod.to_s}.each{|mod|
      assert(result_sub_command_doc_keys.include?(mod.split("::").last), "result_sub_command_doc_keys #{result_sub_command_doc_keys} should include #{mod.split("::").last}")
    }
    result_sub_command_doc.each{|k,v|
      if k.to_s == "UtilTestNoSingleton"
        assert_equal(v, '')
      else
        assert(v != '', "sub_command_doc for #{k} should not be empty")
      end
    }
  end

  def test_document_command_run_composite_command
    test_command = UtilTestComposite.public_method(:test_composite_command)
    test_source_fn = Rubycom::Sources.public_method(:source_command)
    result = Rubycom::YardDoc.document_command(test_command, test_source_fn)
    expected = {
        :full_doc => "A test_command in a composite console",
        :parameters => [
            {:default => nil, :doc => "a test argument", :doc_type => "String", :param_name => "test_arg", :type => :req}
        ],
        :short_doc => "A test_command in a composite console.",
        :tags => [
            {:name => "test_arg", :tag_name => "param", :text => "a test argument", :types => ["String"]},
            {:name => nil, :tag_name => "return", :text => "the test arg", :types => ["String"]}
        ]
    }
    assert_equal(expected, result)
  end

end
