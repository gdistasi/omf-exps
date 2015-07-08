require "core/orbit"


class RessLoggerHelper

	@@defined=false

	def initialize(orbit, process,interface)
		@orbit=orbit
		@name="ressLogger"
        @process=process
        @interface=interface

 	 	if (@@defined == false)
			DefineApp()
			@@defined=true
      		end
	end


	def Install(node_id)
      		appName=@name
      
      		group("node#{node_id}").addApplication(@name, :id => appName ) do |app|
			app.setProperty("process", @process)
			app.setProperty("logfile", "/tmp/rtLog#{node_id}")
			app.setProperty("interval", "3")
            app.setProperty("interface", @interface)
		end	
      
		return Orbit::Application.new(node_id,appName)

	end

	private
	
	def DefineApp

	    defApplication(@name,'srt') do |app|

        app.path = "ruby /usr/local/bin/ResSaver.rb"
        app.appPackage = "bin/ressaver.tar.gz"
        app.version(1,1,1)
        app.shortDescription = "Ressource logging application" 
	    
        app.defProperty('logfile', "Logfile", '-l',
		      {:type => :string, :dynamic => false})
		app.defProperty('process', "ProcessName", '-p',
		      {:type => :string, :dynamic => false})
        app.defProperty('interval', "interval", '-i',
		      {:type => :string, :dynamic => false})
        app.defProperty('interface', "interval", '-a',
		      {:type => :string, :dynamic => false})
	    end

end

end
