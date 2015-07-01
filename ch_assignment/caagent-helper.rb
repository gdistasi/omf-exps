#helper used to instantiate the olsrd (unik) stack on a node
class CaagentHelper
  @@defined=false
  
  def initialize(interfaces, broadcast, mesh, setFlowrates, changeChannels, orbit)
    @interfaces=interfaces
    @isgateway=false
    @name="caagent"
    
    @setFlowrates=setFlowrates
    @changeChannels=changeChannels
    @broadcast=broadcast
    @mesh=mesh
    @orbit=orbit

    if (@@defined==false)
      self.DefineApp
      @@defined=true
    end
  end

  def Install(node_id)

    group("node#{node_id}").addApplication(@name, :id => @name ) do |app|
	  
	  inter_names=Array.new
	  @interfaces.each do |int|
	    inter_names << int.name
	  end

	  interfaces=""
	  @interfaces.each do |int|
	      interfaces="#{interfaces}#{int.name},"
	  end
	  interfaces.chomp!(",")
	  
	  app.setProperty('interfaces', interfaces)
	  
	  app.setProperty('mesh', @mesh)
	  
  	  app.setProperty('broadcast', @broadcast)
	  
	  app.setProperty('setFlowrates', @setFlowrates)
	    
	   if (property.switchOff.to_s=="yes")
		app.setProperty('switchOff', true)
	  end
	  
	  puts "Adding Caagent daemon on node #{node_id}"
   end
            
   return Orbit::Application.new(node_id, @name)

  end
  
  def SetGateway(gw)
    @isgateway=gw
  end
  
  def DefineApp
    defApplication(@name, @name) do |app|
  
      app.path = "/usr/local/bin/caagent >>/var/log/mesh.log 2>&1"
      app.version(1, 1, 1)
      app.shortDescription = "Caagent" 
      app.description = "Channel assignment agent." 
         
      if (@orbit.ECCanServeFiles())      
	app.appPackage = "bin/caagent.tar.gz"
      else
	app.appPackage = "http://#{@orbit.GetECAddress()}:8000/bin/caagent.tar.gz"
      end
      
      app.defProperty('interfaces', "List of mesh interfaces separated by a colon.", "-i", {:type => :string, :dynamic => false})
      #app.defProperty('gateway', "Set this option if the node acts as gateway.", nil, {:type => :boolean, :dynamic => false})
      #app.defProperty('olsrdebug', "Set this option as the debug level for Olsrd.", nil, {:type => :integer, :dynamic => false})
      app.defProperty('switchOff', "Set this option to force a switch off and then a switch on of the interface after a channel change.", "-o", {:type => :boolean, :dynamic => false})
      app.defProperty('broadcast', "Broadcast address to use for CHANNEL_CHANGE messages.", "-b", {:type => :string, :dynamic => false})
      app.defProperty('mesh', "Mesh interface name.", "-m", {:type => :string, :dynamic => false})
      app.defProperty('setFlowrates', "Set to true to ask caagent to set the flowrates.", "-f", {:type => :boolean, :dynamic => false})
            
      allGroups.exec("killall caagent >/dev/null 2>&1; /bin/true")

    end
  end
    
end