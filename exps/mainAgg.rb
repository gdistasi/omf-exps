require "./layer25.rb"
require "./olsr.rb"
require "./80211s.rb"
require "./creass.rb"
require "./aodv.rb"
require "./batman-adv.rb"
require './apps.rb'
require './caserver-helper.rb'
require './ditg-helper.rb'
require './loadplanner.rb'
require './rtlogger-helper.rb'
require './caagent-helper.rb'

defProperty('duration', 120, "Overall duration in seconds of the experiment")
defProperty('topo', 'topos/topo0', "topology to use")
defProperty('range', -1, "range of transmission to force on nodes")
defProperty('links', "", "files which contains the links to be defined on the testbed")
defProperty('stack', "Layer25", "stack to use: Layer25, Olsrd, 802.11s and Aodv")



#Channel reassignment experiment
class ChannelReassignExpAggr < ChannelReassignExp


  #define some properties that can be set from the command line
  def DefProperties
    super
  end
  
  #exec the dynamic part of the experiment
  def Start
        
    #start the applications
    info("Starting applications.")
    @receiverApps.StartAll
    @daemons.StartAll
    @itgManagers.StartAll
    
    #start caagents, if any
    @caagentsApps.StartAll()
    
    #if the caserver node is installed on an external node set some routing rules
    if (property.caserver.to_s!="")
	    #set the ip address of the two interfaces used to realize the link
	    #@orbit.Node(@caserver_node.id).net.e0.up
	    #@orbit.Node(@caserver_node.id).net.e0.ip="192.168.7.#{@caserver_node.id}/24"
	    @orbit.Node(@caserver_node.id).exec("ifconfig #{@orbit.GetControlInterface}:1 192.168.7.#{@caserver_node.id}/24")
	    #@orbit.Node(@receiver.id).net.e0.up
	    #@orbit.Node(@receiver.id).net.e0.ip="192.168.7.#{@receiver.id}/24"
	    @orbit.Node(@receiver.id).exec("ifconfig #{@orbit.GetControlInterface}:1 192.168.7.#{@receiver.id}/24")
	    

	    #add a routing rule to the external node to reach the mesh network through receivers[0]	
	    #The control network is used to make the link
	    @orbit.Node(@caserver_id).exec("ip route del to #{@orbit.GetSubnet}")
	    @orbit.Node(@caserver_id).exec("ip route add to #{@orbit.GetSubnet} via 192.168.7.#{@receiver.id}")
	    
	    #@orbit.Node(@caserver_id).exec("ip route add to #{@orbit.GetSubnet} via #{@orbit.GetControlIp(@receiver)}")


    	    #add a routing rule to mesh nodes to reach the externel node through @receivers[0]
    	    @orbit.GetNodes().each do |n|
		if (n.id!=@receiver.id)
	    	    	@orbit.Node(n.id).exec("ip route del to 192.168.7.#{@caserver_node.id} ")
	    	    	@orbit.Node(n.id).exec("ip route add to 192.168.7.#{@caserver_node.id} via #{@orbit.GetIpFromId(@receiver.id)} ")
			#@orbit.Node(n.id).exec("ip route add to #{@orbit.GetControlIp(@caserver_node)} via #{@orbit.GetIpFromId(@receiver.id)} ")
			#@orbit.Node(n.id).net.e0.route({:op => 'add', :net => '10.42.0.0', 
                	#:gw => '10.40.0.20', :mask => '255.255.0.0'}
		end
	    end
    end

    info("Wait for applications to start")
    wait(5)
    
    if (@assign)
    	info("Starting CAServer")
    	@caserver.StartApplication
    end
    
    if (@numChanges==0)
      interval=@duration
    else
      interval=@duration/@numChanges
    end
    
    numIntervals=@numChanges+1
    
    currTime=0
  
    #sort the flows in ascending order ot starting time
    @flows.Sort	    

    @orbit.WriteInLogs("Starting channel assignment")
    
    #first channel assignment - before the traffic generation starts
    if (@assign)
    	@caserver.SetAlgo(@algo)
    	@caserver.AssignChannels(self.GetInitialDemands(@flows))
    	info("Wait the channel assignment server to complete the first assignment")
    	wait(60)
    end

    wait(10+@extraDelay)

    if (property.freezeTopology.to_s=="yes" and @orbit.class.to_s=="OrbitLayer25")
	info("Freezing topology")
	@orbit.FreezeTopology()
    end
    
    info("Starting rt loggers")
    @rtloggers.StartAll

    @orbit.WriteInLogs("Starting traffic generation")
    
    #start the flows
    info ("Starting traffic generation")
	
    new_demands=Array.new
    
    while (@flows.FlowsLeft()>0)

	 flow=@flows.NextFlow
	  
	 if (flow.start!=currTime)
	   interval=flow.start-currTime
	   
	   @caserver.ReassignChannels(initial_demands)
	   wait(interval)
	   
	   info("Changing network load")
	   currTime=flow.start
	
	   #reset the new_demands array (it is going to be populated)
	   new_demands.clear
	 end
	 
	 #start a new flow through an itgManager; the flow automatically stops.
	 if (flow.bitrate>0)
	  info("Starting a flow from #{flow.sender.id} to #{flow.receiver.id} at #{flow.bitrate} kbps")
	  FindITGManager(flow.sender.id).StartFlow(flow, FindITGRecv(flow.receiver.id))
	  new_demands << flow.GetBitrateMbits
	 end
    end
    
    
    #wait for the last flows to conclude
    wait(@duration-currTime)
    
    info("Stopping applications.")
    @rtloggers.StopAll
    @receiverApps.StopAll
    @daemons.StopAll
    @itgManagers.StopAll
     
    self.CreateVarFile
     
  end
  
end





if (property.stack.to_s=="Layer25")
  orbit=OrbitLayer25.new
elsif (property.stack.to_s=="802.11s")
  orbit=Orbit80211s.new
elsif (property.stack.to_s=="Aodv")
  orbit=OrbitAodv.new
elsif (property.stack.to_s=="BatmanAdv")
  orbit=OrbitBatmanAdv.new
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

#set power of radios
#orbit.SetPower(1)

#set the rate (to 9Mbit/s) (on all the radios)
orbit.SetRate(9)

orbit.SetPower(15)

   
#reads the command line option maxChannelChanges and algo
#exp=ChannelReassignExp.new([1, 4, 1, 5], 0)
exp=ChannelReassignExpAggr.new(0)


exp.SetDuration(property.duration)

orbit.RunExperiment(exp)

