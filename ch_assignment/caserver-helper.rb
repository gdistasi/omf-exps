
$path_caserver="ruby -W0 /usr/local/bin/caserver.rb"

#helper used to instantiate the Channel Assignment Server on a node
class CAServerHelper

	@@defined=false

  
	def initialize(aggregators, gateways, host, channels, initialChannels, orbit)
	  @path=$path_caserver
	  @aggregators=aggregators
	  @gateways=gateways
	  @host=host
	  @orbit=orbit

	  @initialChannels=initialChannels
	  
	  #port where the olsrd plugin wait for connection (in order to give the topology)
	  @olsrPluginPort=9020
	  #port used from nodes to send CHANNEL_INFO and CHANNEL_CHANGE messages
	  @channelInfoPort=9100
	  
	  #channels
	  @channels=channels
	  
	  if (@@defined==false)
	    self.DefineApp
	    @@defined==true
	  end
	  
	end
	 
	                       
	def Install(node_id)
	   name='caserver'	  	   
	
    	   #Usage of caaserver.rb: caaserver.rb host_olsrplugin port channels aggregators gateways nodemesh:port                  
	   @orbit.Node(node_id).addApplication('caaserverapplication', :id => name ) do |app|
	      app.setProperty('aggregators', @aggregators)
	      app.setProperty('gateways', @gateways)
	      app.setProperty('host', "#{@host}:#{@olsrPluginPort}")
	      app.setProperty('channels', "#{MakeStrList(@channels)}")
	      app.setProperty('channelinfoport', "#{@channelInfoPort}")
	      #app.setProperty('rate', "#{@orbit.GetRate}")
	      app.setProperty('rate', "6")
              if (@initialChannels!=nil)
		 app.setProperty('initialChannels', "#{MakeStrList(@initialChannels)}")
	      end
	   end
	   
	   return CAServer.new(node_id, name, @orbit)
	   #Process.wait(proc.pid)
	end
    	  
	def DefineApp
  
	  defApplication('caaserverapplication','caserver') do |app|
	    app.path = "ruby /usr/local/bin/caserver.rb"
	    app.version(1,1,1)
	    app.shortDescription = "Layer 2.5 CAserver" 
	    app.description = "Layer 2.5 Channel Assignment Server." 
	    
	    if (@orbit.GetEnv()!="WILEE")
	      if (@orbit.ECCanServeFiles())      
	        app.appPackage = "bin/caserver.tar.gz"
	      else
	        app.appPackage = "http://#{@orbit.GetECAddress()}:8000/bin/caserver.tar.gz"
	      end
	    end
	    
	    app.defProperty('aggregators', "List of IDs of mesh aggregators separated by a colon.", "--aggregators",
                     {:type => :string, :dynamic => false})
	    app.defProperty('gateways', "List of IDs of mesh gateways separated by a colon. The first gateway is also set as Channel Assignment Server.", 			
	                    "--gateways", {:type => :string, :dynamic => false})
	    app.defProperty('host', "Host (IP:PORT) to contact to get the topology.", "--host",
                     {:type => :string, :dynamic => false})
	    app.defProperty('channels', "Channels to use.", "--channels",
                     {:type => :string, :dynamic => false})
	    app.defProperty('channelinfoport', "Port used for channel info and channel change messages.", "--channelinfoport",
                     {:type => :string, :dynamic => false})
	    app.defProperty('rate', "Rate to be used for interfaces.", "--rate",
                     {:type => :string, :dynamic => false})
	    app.defProperty('initialChannels', "Initial channels to assign.", "--initialChannels",
                     {:type => :string, :dynamic => false})
	  end
	  
	end
	                       
end	           


#class that represents a CAServer instance
class CAServer < Orbit::Application
	def initialize(node, name, orbit=nil)
		super(node, name, orbit)
		
		#default algo
		@algo="FCPRA"
	end

	def SetAlgo(algo)
	  @algo=algo
	end
	
	# set a different number of available channels for the next execution (for example to force only the use of two channels
	# for the first assignment)
        def OverrideNumChannels(chs)
		@numChannels=chs
        end

	def AssignChannels(demands, opt=0)
		DoAssignChannels(demands, true, opt)
	end

	def ReassignChannels(demands, opt=0)
		DoAssignChannels(demands, false, opt)
	end

	private

	def DoAssignChannels(demands, first_assignment, opt=0)
		
		demands_str=""
		demands.each do |d|
			demands_str="#{demands_str}#{d} "
		end
                
		# if algo is MA (Manual Assignment) create the file to be read by ReAssign
		tempFile="/MAoption.txt"
		strChanges=""
		if (@algo=="MA")
		  #file=File.open(tempFile,"w")
		  
		    if (not opt.include?(",S"))
			throw "The option for MA must end with ,S"
		    end	
		    
		    opt.chomp(",S").split(",").each do |change|
		      change.split("-").each do |item|
			strChanges="#{strChanges}#{item} "
		      end
		      strChanges="#{strChanges}\n"
		    end
		    #Write the file on the node
		    @orbit.Node(@node).exec("echo \"#{strChanges}\" > #{tempFile}")
		end	
		
                extraOpt=""
                if (@numChannels!=nil)
			numInt=@orbit.GetInterfaces().size()
			if (Integer(@numChannels) > numInt)
			    info("Setting number of channel for first channel assignment to #{numInt} (because of one interface available).")
			    @numChannels=numInt
			end
		  
			extraOpt="channels #{@numChannels}"

			#set the variable to nil so the next time all the channels are used
			@numChannels=nil
		end
		
		
 
			
		if (first_assignment)
			if (@algo=="MA")
			  SendMessage("#{@algo} #{tempFile} assign #{demands_str} #{extraOpt}")
			else
			  SendMessage("#{@algo} #{opt} assign #{demands_str} #{extraOpt}")
			end
		else
			if (@algo=="MA")
			  SendMessage("#{@algo} #{tempFile} reassign #{demands_str} #{extraOpt}")
			else
  			  SendMessage("#{@algo} #{opt} reassign #{demands_str} #{extraOpt}")
			end	
		end	

	end


end