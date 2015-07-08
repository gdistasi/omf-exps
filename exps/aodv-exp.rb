require 'core/orbit.rb'
require './apps.rb'

require './loadplanner.rb'
require './resslogger.rb'
require './aodv.rb'
require './ditg-helper.rb'


#Channel reassignment experiment

class AodvExp < Orbit::Exp

  #num changes represents the number of times the load changes; duration is the duration of the experiment
  def initialize(interface)
    @receiverApps = Orbit::ApplicationContainer.new
    @itgManagers = Orbit::ApplicationContainer.new
    @daemons = Orbit::ApplicationContainer.new
    @interface = interface

    self.DefProperties

    @demands=Array.new
    property.demands.to_s.split(",").each do |demand|
	@demands << Float(demand)
    end
      
    @extraDelay=0
    if (property.extraDelay.to_s!="")
	@extraDelay=property.extraDelay
    end
    
  end

  #define some properties that can be set from the command line
  def DefProperties
    defProperty('demands', nil, "comma separated list of demands")
    defProperty('extraDelay', "", "extra delay before starting assigning channel and start traffic generation")
    defProperty('protocol', "TCP", "protocol to use for traffic generation")
    defProperty('maliciousNode', "no", "set to  yes to enable malicious nodes")

  end
  
  #install ITGRecv on each receiver and ITGSend and ITGManager on each sender
  def InstallApplications

    #get the senders and receivers
    #orbit manages the topology which also specifies the sender and receiver nodes
    senders=@orbit.GetSenders()
    receivers=@orbit.GetReceivers()
    

 
    #helpers used to allocate ITGRecv on receiving nodes 
    itgReceiver=ITGReceiverHelper.new()

    receivers.each do |receiver|
      itgReceiver.SetLogFile("/tmp/logfile_rec_#{receiver.id}")
      @receiverApps.Add(itgReceiver.Install(receiver.id))
    end
    
    #install the itg daemons and the itg manager
    itgSenderDaemon=ITGDaemonHelper.new
    itgManagerHelper=ITGManagerHelper.new(@orbit)
    
 	
    senders.each do |sender|
	   @daemons.Add(itgSenderDaemon.Install(sender.id))
	   itgManager=itgManagerHelper.Install(sender.id)
	   itgManager.SetProtocol(property.protocol.to_s)
	   @itgManagers.Add(itgManager)
    end
    
    numFlows=senders.size()*receivers.size()
    # info("NumFlows: #{numFlows}")
        
    #the object which allow to get a LoadPlanner (which defines the bitrate of a flow for each interval)
    #helper=LoadPlannerHelper.new(demands, @numChanges, @duration, @maxBitrate) 
    
    @flows=AggregatorFlows.new
    
    i=0
    #determine the traffic load between each sender-receiver couple
    senders.each do |sender|
      receivers.each do |receiver|	
#	@flows.PushFlows(LoadPlanner.new(@demands[i],@duration,sender.id,receiver.id).GetFlows())
        @flows.PushFlows(LoadPlanner.new(@demands[i],@duration,sender.id,receiver.id).GetFlows())
	    i=i+1
      end
    end
    
    info("Installing Logger")
    ress=RessLoggerHelper.new(@orbit,"aodvd",@interface.name)
    @ressloggers=Orbit::ApplicationContainer.new
    @orbit.GetNodes().each do |node|
       @ressloggers.Add(ress.Install(node.id))
    end

  end

  def FindITGManager(sender)
    @itgManagers.apps.each do |app|
      if app.node==sender
	return app
      end
    end
    return nil
  end
  
  def FindITGRecv(receiver)
    @receiverApps.apps.each do |app|
      if app.node==receiver
	return app
      end
    end
    return nil
  end
  
  def getSimpleNodes()
     # return simple nodes
     allNode=@orbit.GetNodes
     receiver=@orbit.GetReceivers
     sender=@orbit.GetSenders
     nodes=allNode-receiver-sender
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
    
    currTime=0
  
    #sort the flows in ascending order ot starting time
    @flows.Sort	

    info("Starting ressources loggers")
    @ressloggers.StartAll

    #start the flows
    info ("Starting traffic generation")
    # @orbit.GetNodes().each do |node|
    #   @orbit.Node(node.id).exec("/tmp/GetMemCpuUsage.sh aodvd")
    # end
        
	
    #set the channel assignment algo to be used for reassignments (either FCPRA or MCVRA)
#    @caserver.SetAlgo(@algo)

    #Used to store demands for Channel Assignment
    new_demands=Array.new

    while (@flows.FlowsLeft()>0)

	 flow=@flows.NextFlow
	  
	 if (flow.start!=currTime)
	   interval=flow.start-currTime
	   wait(interval/2)
    	end
    FindITGManager(flow.sender.id).StartFlow(flow, FindITGRecv(flow.receiver.id))
    end
    
    duration=@duration/5
    wait(duration)
    
    if (property.maliciousNode.to_s!="no")
       info("Malicious Node Activation")
       #@orbit.Node(getSimpleNodes[0].id).exec("iptables -A INPUT -i eth0 -p UDP --dport 654 -m state --state NEW,ETABLISHED,RELATED -j ACCEPT && iptables -A INPUT -i eth0 -j DROP")
       # Drop all traffic
       @orbit.Node(getSimpleNodes[1].id).exec("iptables -A INPUT -i {@interface.name} -p UDP --dport 654 -j ACCEPT; " + 
                                            "iptables -A OUTPUT -o #{@interface.name} -p UDP --dport 654 -j ACCEPT; " +
                                            "iptables -A INPUT -i #{@interface.name} -j DROP; " +
                                            "iptables -A OUTPUT -o #{@interface.name} -j DROP; " +
                                            "iptables -A FORWARD -i #{@interface.name} -j DROP")
        info("Malicious Node = #{getSimpleNodes[0].id}")
    end
       
       # Drop random traffic
    # @orbit.Node(getSimpleNodes[0].id).exec("tc qdisc add dev #{@interface.name} root netem loss 45.0% 25%")
    
    wait(@duration-duration)
    
    info("Stopping applications.")
    @ressloggers.StopAll
#    @rtloggers.StopAll
  
    @receiverApps.StopAll
    @daemons.StopAll
    @itgManagers.StopAll
     
  end
  
end

defProperty('duration', 120, "Overall duration in seconds of the experiment")
defProperty('topo', 'topos/topo0', "topology to use")
defProperty('range', -1, "range of transmission to force on nodes")
defProperty('links', "", "files which contains the links to be defined on the testbed")
defProperty('stack', "Layer25", "stack to use: Layer25 or Olsrd")

if (property.stack.to_s=="Aodv")
  orbit=OrbitAodv.new
end

if (property.env.to_s=="ORBIT")
    interface=Orbit::Interface.new("wlan0","WifiAdhoc")
    orbit.AddInterface(interface)
	#orbit.AddInterface(Orbit::Interface.new("wlan1","WifiAdhoc"))
else
    interface=Orbit::Interface.new("eth0","Ether")
    orbit.AddInterface(interface)
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

#set the rate (on all the radios)
orbit.SetRate(9)
   
#reads the command line option maxChannelChanges and algo
exp=AodvExp.new(interface)

exp.SetDuration(property.duration)

orbit.RunExperiment(exp)


if __FILE__ == $0

end
