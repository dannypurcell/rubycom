require "#{File.dirname(__FILE__)}/../../lib/rubycom/error_handler.rb"

require "#{File.dirname(__FILE__)}/util_test_module.rb"
require "#{File.dirname(__FILE__)}/util_test_composite.rb"
require "#{File.dirname(__FILE__)}/util_test_no_singleton.rb"

require 'test/unit'

class ErrorHandlerTest < Test::Unit::TestCase

  def capture_err(&block)
    original_stderr = $stderr
    $stderr = fake = StringIO.new
    begin
      yield
    ensure
      $stderr = original_stderr
    end
    fake.string
  end

  def test_handle_error
    test_error = StandardError.new("test error")
    test_cli_output = 'some test output'

    result = capture_err { Rubycom::ErrorHandler.handle_error(test_error, test_cli_output) }

    assert_true(result.gsub(/\s|\n|\r\n/,'').include?(test_error.to_s.gsub(/\s|\n|\r\n/,'')),"#{result} should include #{test_error.to_s}")
    assert_true(result.gsub(/\s|\n|\r\n/,'').include?(test_cli_output.gsub(/\s|\n|\r\n/,'')),"#{result} should include #{test_cli_output}")
  end

end
