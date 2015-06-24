
class Helper
	@@defined=false
  
	def initialize()
	  if (@@defined==false)
	    DefineApp()
	    @@defined=true
	  end
	end
	

end