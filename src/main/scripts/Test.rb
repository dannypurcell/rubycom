##
# A Test command Line tool
##
module Test

  # A method that tells us what kitties say
  #
  # @param [String] say what kitties should say
  def self.kitties(say='MAOW!',count)
    puts "Kitties: #{say.count.times}"
  end

  # A test method for other stuff
  #
  # @param [Integer] count the count
  def test_count(count)
    count += 1
  end
  include Rubycom
end