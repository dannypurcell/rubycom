module UtilTestComposite
  # Sub-Module in UtilTestComposite
  module UtilTestSubModule

    # Test command in a sub-module as part of UtilTestComposite
    #
    # @param [String] test the testing parameter to output
    # @return [String] a String representation of the input parameter
    def self.sub_module_command(test)
      "test = #{test}"
    end
  end
end