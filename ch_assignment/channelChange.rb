require "routing/layer25.rb"
require "routing/olsr.rb"
require "ch_assignmanet/creass.rb"

#Channel reassignment experiment

class ChannelChangeTimes < ChannelReassignExp

  
  def SetUpNodes
    @nodes=@orbit.GetNodes()
    
    #initial setup for radios
    if (@nodes.size==2)
      
      info("Setting interface 0 of node 0 to channel #{@orbit.channels[0]}")
      @orbit.GetGroupInterface(@nodes[0], 
                               @orbit.GetInterfaces[0]).channel="#{@orbit.channels[0]}"
      
      info("Setting interface 1 of node 0 to channel #{@orbit.channels[2]}")
      @orbit.GetGroupInterface(@nodes[0], 
                               @orbit.GetInterfaces[1]).channel="#{@orbit.channels[2]}"
    
      
      if (@orbit.class.to_s!="OrbitLayer25")
	info("Setting interface 1 of node0 down.") 	     
	@orbit.GetGroupInterface(@nodes[0], @orbit.GetInterfaces[1]).down
      end
      
      info("Setting interface 0 of node 1 down to channel #{@orbit.channels[0]}.")

      @orbit.GetGroupInterface(@nodes[1], @orbit.GetInterfaces[0]).channel="#{@orbit.channels[0]}"
      
      info("Setting interface 1 of node 1 down to channel #{@orbit.channels[1]}.")

      @orbit.GetGroupInterface(@nodes[1], @orbit.GetInterfaces[1]).channel="#{@orbit.channels[1]}"
    

    end
    
    self.SetIptableRules()
    
  end
  
  # not good
  def SetIptableRules
       if @orbit.class.to_s.include?("Olsrd")
    
    
	      @orbit.Node(@nodes[0]).exec("iptables -i #{@orbit.GetInterfaces()[1].name} -I INPUT 1 -j DROP") 
      	      @orbit.Node(@nodes[0]).exec("iptables -o #{@orbit.GetInterfaces()[1].name} -I OUTPUT 1 -j DROP") 

           
       end
  end
          
  def DeleteIptableRules
       
    if @orbit.class.to_s.include?("Olsrd")
    
    
	      @orbit.Node(@nodes[0]).exec("iptables -i #{@orbit.GetInterfaces()[1].name} -D INPUT -j DROP") 
      	      @orbit.Node(@nodes[0]).exec("iptables -o #{@orbit.GetInterfaces()[1].name} -D OUTPUT -j DROP") 

           
       end
  end
  
  #exec the dynamic part of the experiment
  def Start
        

    
    #start the applications
    info("Starting applications.")
    @receiverApps.StartAll
    @daemons.StartAll
    @itgManagers.StartAll

    info("Wait for applications to start")
    wait(5)
    
    numRepetitions=3
    interval=120
    
    duration=(numRepetitions)*interval+30

    
    currTime=0
  
    @flows=AggregatorFlows.new
    
    flow=Flow.new(0, 500, @orbit.GetSenders()[0].id, @orbit.GetReceivers()[0].id)
   
    flow.SetEnd(duration)
    
    @flows.Push(flow)
    
    info("Starting rt loggers")
    @rtloggers.StartAll

    #start the flows
    info ("Starting traffic generation")
	
    while (@flows.FlowsLeft()>0)
	 flow=@flows.NextFlow
	 #start a new flow through an itgManager; the flow automatically stops.
	 if (flow.bitrate>0)
	  info("Starting a flow from #{flow.sender.id} to #{flow.receiver.id} at #{flow.bitrate} kbps")
	  FindITGManager(flow.sender.id).StartFlow(flow, FindITGRecv(flow.receiver.id))
	 end
    end
       
    k=0
    
    if (property.freezeTopology.to_s=="yes" and @orbit.class.to_s=="OrbitLayer25")
	info("Freezing topology")
	@orbit.FreezeTopology()
    end
    
    wait(30)
    
    while (k<numRepetitions) do
    
      
      info("Changing channels...")
      
      if (@nodes.size==2)
	
	info("Setting interface #{k%2} of node 1 on channel #{@orbit.channels[4]}.")
	@orbit.GetGroupInterface(@nodes[1], @orbit.GetInterfaces[k%2]).channel="#{@orbit.channels[4]}"

	if (property.switchOff.to_s!="no")
	    info("Also setting interface down and then up.")
	    @orbit.GetGroupInterface(@nodes[1], @orbit.GetInterfaces[k%2]).down
    	    @orbit.GetGroupInterface(@nodes[1], @orbit.GetInterfaces[k%2]).up
	end
	
	
	info("Setting interface #{(k+1)%2} of node 1 to channel #{@orbit.channels[0]}")
	@orbit.GetGroupInterface(@nodes[1], @orbit.GetInterfaces[(k+1)%2]).channel="#{@orbit.channels[0]}"
      end  
      
      @nodes.each do |node|
	@orbit.GetInterfaces().each do |ifn|
	  
	  @orbit.Node(@nodes[0].id).exec("iwconfig #{ifn.name} >> /var/log/mesh.log")
        
	end
      end
	                            
      k=k+1
 
      wait(interval)

      
    end
    
    info("Stopping applications.")
    @rtloggers.StopAll
    @receiverApps.StopAll
    @daemons.StopAll
    @itgManagers.StopAll
          
    self.DeleteIptableRules()

          
  end
 
end



defProperty('duration', 120, "Overall duration in seconds of the experiment")
defProperty('topo', 'topos/topoSmallOrbit', "topology to use")
defProperty('range', -1, "range of transmission to force on nodes")
defProperty('links', "", "files which contains the links to be defined on the testbed")
defProperty('stack', "Layer25", "stack to use: Layer25 or Olsrd")

if (property.stack.to_s=="Layer25")
  orbit=OrbitLayer25.new
else
  orbit=OrbitOlsr.new
end

if (property.env.to_s=="ORBIT" or property.env.to_s=="NEPTUNE")
	orbit.AddInterface(Orbit::Interface.new("wlan0","WifiAdhoc"))
	orbit.AddInterface(Orbit::Interface.new("wlan1","WifiAdhoc"))
else
	orbit.AddInterface(Orbit::Interface.new("eth0","Ether"))
	orbit.AddInterface(Orbit::Interface.new("eth2","Ether"))
end

#ask orbit to set up the radios
orbit.SetRadios(true)

#read the topology from the file property.topo
topo=Orbit::Topology.new(property.topo, orbit)

#define the links to be used (enforced via iptable)
if (property.links.to_s!="")
	topo.AddLinksFromFile(property.links.to_s)
end

#if the property is defined add all the links shorter than range
if (property.range!=-1)
	topo.AddLinksInRange(property.range)
end

#pass the topology specification to Orbit that will enforce it
orbit.UseTopo(topo)

#set a fixed rate on all the radios
orbit.SetRate(9)
   
#reads the command line option maxChannelChanges and algo
exp=ChannelChangeTimes.new


orbit.RunExperiment(exp)

