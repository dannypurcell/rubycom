module Rubycom

  def self.included(base)
    base_singleton_methods = base.singleton_methods(false)
    puts "BaseClass: #{base}"
    puts "Public/ProtectedStaticMethods:"
    base_singleton_methods.each{ |sym|
      m = base.public_method(sym)
      req_params=[]
      optional_params=[]
      m.parameters.each{|opt_req,symbol|
        req_params<<symbol if opt_req==:req
        optional_params<<symbol if opt_req==:opt
      }
      msg = "Usage: #{m.name} [option]"
      req_params.each{|param|
        msg << " #{param}"
      }
      msg<<"\n"
      optional_params.each{|option|
        msg<<"\t -#{option}\n"
      }

      puts msg
    }
  end

end

##
# A Test command Line tool
##
module Test

  ##
  # A method that tells us what kitties say
  #
  # @param say what kitties say
  # @return void
  ##
  def self.kitties(say='MAOW!')
    puts "Kitties: #{say}"
  end
  include Rubycom
end