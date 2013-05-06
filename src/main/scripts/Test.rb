##
# A Test command Line tool
##
module Test

  # A method that tells us what kitties say
  #
  # @param [String] say what kitties should say
  # @param [Integer] count how many times kitties say it
  def self.kitties(say='MAOW!',count)
    puts "Kitties: #{say.count.times}"
  end

  # A method that tests a code value
  #
  # @param [Integer] test_code the code value to test
  # @return a return value
  def self.test(test_code)
    case test_code
      when 1
        return 0
      else
        return 1
    end
  end

  # A test method for other stuff
  #
  # @param [Integer] count the count
  def test_count(count)
    count += 1
  end
  include Rubycom
end