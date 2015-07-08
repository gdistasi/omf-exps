require "core/orbit"


class RoutingTableLoggerHelper

	@@defined=false

	def initialize(orbit, stack)
		@orbit=orbit
		@name="saveroutingtable"
      		@stack=stack

 	 	if (@@defined == false)
			DefineApp()
			@@defined=true
      		end
	end


	def Install(node_id)
      		appName=@name
      
      		group("node#{node_id}").addApplication(@name, :id => appName ) do |app|
			app.setProperty("stack", @stack)
			app.setProperty("logfile", "/tmp/rtLog#{node_id}")
			app.setProperty("interval", "3")
		end	
      
		return Orbit::Application.new(node_id,appName)

	end

	private
	
	def DefineApp

	    defApplication(@name,'srt') do |app|

	    	app.path = "ruby /usr/local/bin/SaveRoutingTable.rb"
		
		if (@orbit.ECCanServeFiles())      
		   app.appPackage = "bin/saveroutingtable.tar.gz"
		else
		    app.appPackage = "http://#{@orbit.GetECAddress()}:8000/bin/saveroutingtable.tar.gz"
		end
		
		app.version(1,1,1)
	    	app.shortDescription = "Application that checks the routing table" 
	    
	    	app.defProperty('logfile', "Logfile", '-l',
		      {:type => :string, :dynamic => false})
		app.defProperty('stack', "Stack", '-s',
		      {:type => :string, :dynamic => false})
	        app.defProperty('interval', "interval time between checks at the routing table", '-i',
		      {:type => :string, :dynamic => false})
	    end


	end
	
	

end

