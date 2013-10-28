require "#{File.dirname(__FILE__)}/../../lib/rubycom/helpers.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class HelpersTest < Test::Unit::TestCase

  def test_format_tags_nil
    tag_list = nil
    desc_width = 90
    result = Rubycom::Helpers.format_tags(tag_list, desc_width)
    expected = {:others => [], :params => [], :returns => []}
    assert_equal(expected, result)
  end

  def test_format_tags_empty
    tag_list = []
    desc_width = 90
    result = Rubycom::Helpers.format_tags(tag_list, desc_width)
    expected = {:others => [], :params => [], :returns => []}
    assert_equal(expected, result)
  end

  def test_format_tags_wrong_type
    tag_list = [[], 1, ""]
    desc_width = 90
    result = nil
    assert_raise(ArgumentError) { result = Rubycom::Helpers.format_tags(tag_list, desc_width) }
    expected = nil
    assert_equal(expected, result)
  end

  def test_format_tags_incorrect_keys
    tag_list = [{}]
    desc_width = 90
    result = nil
    assert_raise(KeyError) { result = Rubycom::Helpers.format_tags(tag_list, desc_width) }
    expected = nil
    assert_equal(expected, result)
  end

  def test_format_tags_incorrect_value_types
    tag_list = [
        {name: '', tag_name: '', text: '', types: ''}
    ]
    desc_width = 90
    result = nil
    assert_raise(ArgumentError) { result = Rubycom::Helpers.format_tags(tag_list, desc_width) }
    expected = nil
    assert_equal(expected, result)
  end

  def test_format_tags_empty_values
    tag_list = [
        {name: '', tag_name: '', text: '', types: []}
    ]
    desc_width = 90
    result = Rubycom::Helpers.format_tags(tag_list, desc_width)
    expected = {
        :others => ["  -  \n"],
        :params => [],
        :returns => []
    }
    assert_equal(expected, result)
  end

  def test_format_tags_single_other
    tag_list = [
        {name: 'test_opt', tag_name: 'See Also', text: 'a testing option', types: [String]}
    ]
    desc_width = 90
    result = Rubycom::Helpers.format_tags(tag_list, desc_width)
    expected = {
        :others => ["[String] See Also: test_opt  -  a testing option\n"],
        :params => [],
        :returns => []
    }
    assert_equal(expected, result)
  end

  def test_format_tags_single_other_no_types
    tag_list = [
        {name: 'test_opt', tag_name: 'See Also', text: 'a testing option', types: []}
    ]
    desc_width = 90
    result = Rubycom::Helpers.format_tags(tag_list, desc_width)
    expected = {
        :others => ["See Also: test_opt  -  a testing option\n"],
        :params => [],
        :returns => []
    }
    assert_equal(expected, result)
  end

  def test_format_tags_single_other_nil_name
    tag_list = [
        {name: nil, tag_name: 'See Also', text: 'a testing option', types: []}
    ]
    desc_width = 90
    result = Rubycom::Helpers.format_tags(tag_list, desc_width)
    expected = {
        :others => ["          -  a testing option\n"],
        :params => [],
        :returns => []
    }
    assert_equal(expected, result)
  end

  def test_format_tags_single_param
    tag_list = [
        {name: 'test_opt', tag_name: 'param', text: 'a testing option', types: [String]}
    ]
    desc_width = 90
    result = Rubycom::Helpers.format_tags(tag_list, desc_width)
    expected = {
        :others => [],
        :params => ["[String] test_opt  -  a testing option\n"],
        :returns => []
    }
    assert_equal(expected, result)
  end

  def test_format_tags_single_return
    tag_list = [
        {name: 'test_opt', tag_name: 'return', text: 'a testing option', types: [String]}
    ]
    desc_width = 90
    result = Rubycom::Helpers.format_tags(tag_list, desc_width)
    expected = {
        :others => [],
        :params => [],
        :returns => ["[String] return    -  a testing option\n"]
    }
    assert_equal(expected, result)
  end

  def test_format_tags_multi_mixed
    tag_list = [
        {name: 'test_arg', tag_name: 'param', text: 'a testing argument', types: [String]},
        {name: 'test_opt', tag_name: 'param', text: 'a testing option', types: [String]},
        {name: 'test_ret', tag_name: 'return', text: 'a test return', types: [String]},
        {name: 'Other_doc', tag_name: 'SeeAlso', text: 'some more test docs', types: []},
        {name: 'Link', tag_name: 'link', text: 'a neat test link', types: [Object]},
    ]
    desc_width = 90
    result = Rubycom::Helpers.format_tags(tag_list, desc_width)
    expected = {
        :others => [
            "SeeAlso: Other_doc  -  some more test docs\n",
            "[Object] link: Link      -  a neat test link\n"
        ],
        :params => [
            "[String] test_arg  -  a testing argument\n",
            "[String] test_opt  -  a testing option\n"
        ],
        :returns => [
            "[String] return    -  a test return\n"
        ]
    }
    assert_equal(expected, result)
  end

  def test_format_command_list_empty
    command_doc_hsh = {}
    desc_width = 90
    result = Rubycom::Helpers.format_command_list(command_doc_hsh, desc_width)
    expected = []
    assert_equal(expected, result)
  end

  def test_format_command_list_non_string_values
    tst_obj = Object.new
    command_doc_hsh = {test: 'value', another: [123, {of: 'test'}, [tst_obj]]}
    desc_width = 90
    result = Rubycom::Helpers.format_command_list(command_doc_hsh, desc_width)
    expected = [
        "test     -  value\n",
        "another  -  [123, {:of=>\"test\"}, [#{tst_obj}]]\n"
    ]
    assert_equal(expected, result)
  end

  def test_format_command_list_single
    command_doc_hsh = {test_command: "a simple test command"}
    desc_width = 90
    result = Rubycom::Helpers.format_command_list(command_doc_hsh, desc_width)
    expected = ["test_command  -  a simple test command\n"]
    assert_equal(expected, result)
  end

  def test_format_command_list_multi
    command_doc_hsh = {
        test_command: "a simple test command which happens to have a rather overly verbose description expected to be "+
            "wrapped in order to make said description fit in a nice column",
        test_command_with_a_long_name_for_testing_things: 'a simple test command'
    }
    desc_width = 90
    result = Rubycom::Helpers.format_command_list(command_doc_hsh, desc_width)
    expected = [
        "test_command                                      -  a simple test command which happens\n"+
            "                                                     to have a rather overly verbose\n"+
            "                                                     description expected to be wrapped in\n"+
            "                                                     order to make said description fit in\n"+
            "                                                     a nice column\n",
        "test_command_with_a_long_name_for_testing_things  -  a simple test command\n"
    ]
    assert_equal(expected, result)
  end

  def test_format_command_list_missing_doc
    command_doc_hsh = {
        test_command: nil,
        test_command_with_a_long_name_for_testing_things: 'a simple test command'
    }
    desc_width = 90
    result = Rubycom::Helpers.format_command_list(command_doc_hsh, desc_width)
    expected = [
        "test_command                                      -  \n",
        "test_command_with_a_long_name_for_testing_things  -  a simple test command\n"
    ]
    assert_equal(expected, result)
  end

  def test_format_command_list_missing_name
    command_doc_hsh = {
        nil => "some test command",
        test_command_with_a_long_name_for_testing_things: 'a simple test command'
    }
    desc_width = 90
    result = Rubycom::Helpers.format_command_list(command_doc_hsh, desc_width)
    expected = [
        "                                                  -  some test command\n",
        "test_command_with_a_long_name_for_testing_things  -  a simple test command\n"
    ]
    assert_equal(expected, result)
  end

  def test_format_command_list_missing_name_and_doc
    command_doc_hsh = {
        nil => nil,
        test_command_with_a_long_name_for_testing_things: 'a simple test command'
    }
    desc_width = 90
    result = Rubycom::Helpers.format_command_list(command_doc_hsh, desc_width)
    expected = [
        "                                                  -  \n",
        "test_command_with_a_long_name_for_testing_things  -  a simple test command\n"
    ]
    assert_equal(expected, result)
  end

  def test_get_separator_empty
    name = ''
    longest_name = ''
    sep = ''
    result = Rubycom::Helpers.get_separator(name, longest_name, sep)
    assert(result.include?(sep), "calculated separator #{result} should include the given separator")
    assert(result.gsub(sep, '').gsub(' ', '').empty?, "calculated separator should only consist of whitespace and the given separator")
    assert("#{name}#{result}".length == longest_name.size+sep.size,
           "name.length+result.length should be #{longest_name.length+sep.length} but was #{"#{name}#{result}".length}")
  end

  def test_get_separator
    name = 'test_command'
    longest_name = 'test_command_with_a_long_name_for_testing_things'
    sep = ' - '
    result = Rubycom::Helpers.get_separator(name, longest_name, sep)
    assert(result.include?(sep), "calculated separator #{result} should include the given separator")
    assert(result.gsub(sep, '').gsub(' ', '').empty?, "calculated separator should only consist of whitespace and the given separator")
    assert("#{name}#{result}".length == longest_name.size+sep.size,
           "name.length+result.length should be #{longest_name.length+sep.length} but was #{"#{name}#{result}".length}")
  end

  def test_get_separator_empty_sep
    name = 'test_command'
    longest_name = 'test_command_with_a_long_name_for_testing_things'
    sep = ''
    result = Rubycom::Helpers.get_separator(name, longest_name, sep)
    assert(result.include?(sep), "calculated separator #{result} should include the given separator")
    assert(result.gsub(sep, '').gsub(' ', '').empty?, "calculated separator should only consist of whitespace and the given separator")
    assert("#{name}#{result}".length == longest_name.size+sep.size,
           "name.length+result.length should be #{longest_name.length+sep.length} but was #{"#{name}#{result}".length}")
  end

  def test_get_separator_empty_name
    name = ''
    longest_name = 'test_command_with_a_long_name_for_testing_things'
    sep = ' - '
    result = Rubycom::Helpers.get_separator(name, longest_name, sep)
    assert(result.include?(sep), "calculated separator #{result} should include the given separator")
    assert(result.gsub(sep, '').gsub(' ', '').empty?, "calculated separator should only consist of whitespace and the given separator")
    assert("#{name}#{result}".length == longest_name.size+sep.size,
           "name.length+result.length should be #{longest_name.length+sep.length} but was #{"#{name}#{result}".length}")
  end

  def test_get_separator_name_longer_than_longest
    name = 'test_command_with_a_long_name_for_testing_things'
    longest_name = 'test_command'
    sep = ' - '
    result = Rubycom::Helpers.get_separator(name, longest_name, sep)
    assert(result.include?(sep), "calculated separator #{result} should include the given separator")
    assert(result.gsub(sep, '').gsub(' ', '').empty?, "calculated separator should only consist of whitespace and the given separator")
    assert("#{name}#{result}".length == name.size+sep.size,
           "name.length+result.length should be #{name.size+sep.size} but was #{"#{name}#{result}".length}")
  end

  def test_format_command_summary_empty
    command_name = ''
    command_description = ''
    separator = ''
    max_width = 90
    result = Rubycom::Helpers.format_command_summary(command_name, command_description, separator, max_width)
    expected = "\n"
    assert_equal(expected, result)
  end

  def test_format_command_summary_short
    command_name = 'test_command'
    command_description = 'a simple test command'
    separator = ' - '
    max_width = 90
    result = Rubycom::Helpers.format_command_summary(command_name, command_description, separator, max_width)
    expected = "test_command - a simple test command\n"
    assert_equal(expected, result)
  end

  def test_format_command_summary_long_name
    command_name = 'test_command_with_a_long_name_for_testing_things'
    command_description = 'a simple test command'
    separator = ' - '
    max_width = 90
    result = Rubycom::Helpers.format_command_summary(command_name, command_description, separator, max_width)
    expected = "test_command_with_a_long_name_for_testing_things - a simple test command\n"
    assert_equal(expected, result)
  end

  def test_format_command_summary_name_over_max_width
    command_name = 'test_command_with_a_long_name_for_testing_things'
    command_description = 'a simple test command'
    separator = ' - '
    max_width = 10
    result = nil
    assert_raise(ArgumentError) { result = Rubycom::Helpers.format_command_summary(command_name, command_description, separator, max_width) }
    expected = nil
    assert_equal(expected, result)
  end

  def test_format_command_summary_name_sep_equal_max_width
    command_name = 'test_command'
    command_description = 'a simple test command'
    separator = ' - '
    max_width = command_name.size+separator.size
    result = Rubycom::Helpers.format_command_summary(command_name, command_description, separator, max_width)
    expected = "test_command - a\n               simple\n               test\n               command\n"
    assert_equal(expected, result)
  end

  def test_format_command_summary_long_desc
    command_name = 'test_command'
    command_description = "a simple test command which happens to have a rather overly verbose description expected to"+
        " be wrapped in order to make said description fit in a nice column"
    separator = ' - '
    max_width = 70
    result = Rubycom::Helpers.format_command_summary(command_name, command_description, separator, max_width)
    expected = "test_command - a simple test command which happens to have a rather\n               overly verbose "+
        "description expected to be wrapped in\n               order to make said description fit in a nice column\n"
    assert_equal(expected, result)
  end

  def test_format_command_summary_long_desc_short_width
    command_name = 'test_command'
    command_description = "a simple test command which happens to have a rather overly verbose description expected"+
        " to be wrapped in order to make said description fit in a nice column"
    separator = ' - '
    max_width = 16
    result = Rubycom::Helpers.format_command_summary(command_name, command_description, separator, max_width)
    expected = "test_command - a\n"+
        "               simple\n"+
        "               test\n"+
        "               command\n"+
        "               which\n"+
        "               happens\n"+
        "               to\n"+
        "               have\n"+
        "               a\n"+
        "               rather\n"+
        "               overly\n"+
        "               verbose\n"+
        "               description\n"+
        "               expected\n"+
        "               to\n"+
        "               be\n"+
        "               wrapped\n"+
        "               in\n"+
        "               order\n"+
        "               to\n"+
        "               make\n"+
        "               said\n"+
        "               description\n"+
        "               fit\n"+
        "               in\n"+
        "               a\n"+
        "               nice\n"+
        "               column\n"
    assert_equal(expected, result)
  end

  def test_format_command_summary_long_separator
    command_name = 'test_command'
    command_description = 'a simple test command'
    separator = ' ----------------------------------------------------------------------------------------------- '
    max_width = 16
    result = nil
    assert_raise(ArgumentError) { result = Rubycom::Helpers.format_command_summary(command_name, command_description, separator, max_width) }
    expected = nil
    assert_equal(expected, result)
  end

  def test_word_wrap_empty
    text = ''
    line_width=10
    prefix=''
    result = Rubycom::Helpers.word_wrap(text, line_width, prefix)
    expected = ''
    assert_equal(expected, result)
  end

  def test_word_wrap_less_than_line_width
    text = '1 2 3 4 5 6 7 8 9'
    line_width = 17
    prefix = ''
    result = Rubycom::Helpers.word_wrap(text, line_width, prefix)
    expected = '1 2 3 4 5 6 7 8 9'
    assert_equal(expected, result)
  end

  def test_word_wrap_greater_than_line_width
    text = '1 2 3 4 5 6 7 8 9'
    line_width = 10
    prefix = ''
    result = Rubycom::Helpers.word_wrap(text, line_width, prefix)
    expected = "1 2 3 4 5\n6 7 8 9"
    assert_equal(expected, result)
  end

  def test_word_wrap_with_prefix
    text = '1 2 3 4 5 6 7 8 9'
    line_width = 10
    prefix = ' '
    result = Rubycom::Helpers.word_wrap(text, line_width, prefix)
    expected = "1 2 3 4 5\n 6 7 8 9"
    assert_equal(expected, result)
  end

  def test_word_wrap_with_long_prefix
    text = '1 2 3 4 5 6 7 8 9'
    line_width = 10
    prefix = ' ' * 40
    result = Rubycom::Helpers.word_wrap(text, line_width, prefix)
    expected = "1 2 3 4 5\n                                        6 7 8 9"
    assert_equal(expected, result)
  end

end
