require 'core/orbit.rb'

class OrbitDot11s < Orbit 
    
 def InstallStack
    
    defApplication('dot11sApplication', 'dot11s') do |app|
  
      app.path = "/usr/local/bin/dot11s.rb"  
      app.version(1, 1, 1)
      app.shortDescription = "Dot11s Routing" 
      app.description = "Dot11s routing stack." 
 
      app.defProperty('id', 'Node id', "--id", 
		    {:type => :integer, :dynamic => false})
      app.defProperty('setradios', 'Auto set of radios', "--setradios", 
		    {:type => :boolean, :dynamic => false})
      add.defProperty('interfaces', "List of mesh interfaces separated by a colon.", "--interfaces",
                     {:type => :string, :dynamic => false})
 
    end
    
    @nodes.each do |node|
      group("node#{node.id}").addApplication('dot11sApplication') do |app|
	  app.setProperty('id', node.id)
	  app.setProperty('setradios', not @setradios)
	  app.setProperty('interfaces', "ath0,ath1")
      end
     
    end
    
 end
 
 def StartStack
   allGroups.startApplication('dot11sApplication')
 end
 
end
