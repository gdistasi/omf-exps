require 'core/orbit.rb'
require 'core/apps.rb'
require 'ch_assignment/caserver-helper.rb'
require 'traffic/ditg-helper.rb'
require 'traffic/loadplanner.rb'
require 'utils/rtlogger-helper.rb'
require 'ch_assignment/caagent-helper.rb'

#Channel reassignment experiment
class ChannelReassignExp < Orbit::Exp

  #num changes represents the number of times the load changes; duration is the duration of the experiment
  def initialize(demands=0, numChanges=2, duration=120)
    @duration=duration
    @numChanges=numChanges
    @maxBitrate=5000
   
    @receiverApps = Orbit::ApplicationContainer.new
    @itgManagers = Orbit::ApplicationContainer.new
    @daemons = Orbit::ApplicationContainer.new

    self.DefProperties

    @algo=property.algo.to_s
    @maxChannelChanges=property.maxNumChannelChanges	
    
    #if (property.demands!=nil)
      @demands=Array.new
      property.demands.to_s.split(",").each do |demand|
	@demands << Float(demand)
      end
    #end
      
    if (property.initialDemands.to_s!="")
      @initial_demands=Array.new
      property.initialDemands.to_s.split(",").each do |demand|
	@initial_demands << Float(demand)
      end
    end

    if (property.dontassign.to_s!="")
	@assign=false
    else
	@assign=true
    end

    @extraDelay=0
    if (property.extraDelay.to_s!="")
	@extraDelay=property.extraDelay
    end
    
    @protocols=property.protocol.to_s.split(",")
    
  end

  #define some properties that can be set from the command line
  def DefProperties
    defProperty('maxNumChannelChanges', 5, "max num of channel changes for MVCRA")
    defProperty('caOption', "5", "generic option for the CA algorithm")
    defProperty('algo', 'FCPRA', "channel assignment algorithm to use: FCPRA, MVCRA")
    defProperty('demands', nil, "comma separated list of demands")
    defProperty('initialDemands', "", "comma separated list of initial demands")
    defProperty('caserver', "", "caserver node id")
    defProperty('dontassign', "", "if set, the initial channels are never changed (for debugging purposes)")
    defProperty('extraDelay', "", "extra delay before starting assigning channel and start traffic generation")
    defProperty('protocol', "TCP", "protocol to use for traffic generation")
    defProperty('initialAlgo', "FCPRA", "protocol to use for the first channel assignment")
    defProperty('initialAlgoOption', "2", "option for the first channel assignment")
    defProperty('biflow', "no", "set to yes if you want a flow also in the gateway -> aggregator direction")
    defProperty('waiting_times', nil, "array of times to wait between each channel change")
    defProperty('dirtyfix', "no", "set to yes if you want to add a fictitious routing rule on sender and receiver to avoid the SIG PIPE problem...")
    defProperty('avoidTcpRst', "no", "set to yes if you want to avoid that routers sends TCP RST messages")
    defProperty('arpFilter', "no", "set to yes if you want to enable arp_filter option")

  end
  
  #install ITGRecv on each receiver and ITGSend and ITGManager on each sender
  def InstallApplications

    #get the senders and receivers
    #orbit manages the topology which also specifies the sender and receiver nodes
    senders=@orbit.GetSenders()
    receivers=@orbit.GetReceivers()
    
    #helpers used to allocate ITGRecv on receiving nodes 
    itgReceiver=ITGReceiverHelper.new(@orbit)

    receiverNodes=Array.new(receivers)
    
    # if we want a flow for each direction install itgrecv also on both aggregators and senders
    if (property.biflow.to_s=="yes")
	senders.each do |n|
	  receiverNodes << n
	end
    end	 
   
    #there is a receiver for each type of protocol so we
    #associate a signaling port to each of them
    sigChPort=9000
    @mapProtocols=Hash.new
    @protocols.each do |proto|
	@mapProtocols[proto]=sigChPort
	sigChPort=sigChPort+1
    end
    
    receiverNodes.each do |receiver|
      @protocols.each do |proto|
	itgReceiver.SetLogFile("/tmp/ditg.log-#{proto}-node-#{receiver.id}")
	itgReceiver.SetSigChannelPort(@mapProtocols[proto])
	@receiverApps.Add(itgReceiver.Install(receiver.id))
      end
  
      if (property.dirtyfix.to_s=="yes")
	    @orbit.RunOnNode(receiver, "ip route add to 5.100.0.0/16 dev #{@orbit.GetControlInterface()}")
      end
    end
    
    #install the itg daemons and the itg manager
    itgSenderDaemon=ITGDaemonHelper.new(@orbit)
    itgManagerHelper=ITGManagerHelper.new(@orbit)
    
    senderNodes = Array.new(senders)
    
    # if we want a flow for each direction install itgrecv also on both aggregators and senders
    if (property.biflow.to_s=="yes")
	receivers.each do |n|
	  senderNodes << n
	end
    end	 
    
 	
    senderNodes.each do |sender|
	@daemons.Add(itgSenderDaemon.Install(sender.id))
	itgManager=itgManagerHelper.Install(sender.id)
	@itgManagers.Add(itgManager)
	if (property.dirtyfix.to_s=="yes")
	  @orbit.RunOnNode(sender, "ip route add to 5.100.0.0/16 dev #{@orbit.GetControlInterface()}")
	end
    end
    
    numFlows=senders.size()*receivers.size()
    
        
    #the object which allow to get a LoadPlanner (which defines the bitrate of a flow for each interval)
    #helper=LoadPlannerHelper.new(demands, @numChanges, @duration, @maxBitrate) 
    @flows=AggregatorFlows.new
    
    if property.caOption.to_s.include?(":")
       @wait_after_start=25
       #@wait_after_change=100
       
       if property.waiting_times.to_s!=nil
	    @waiting_times = Array.new
	    property.waiting_times.to_s.split(",").each do |wt|
	      @waiting_times << Float(wt)
	    end
       else
	    @waiting_times=[90]
       end	
	
       info( "Waiting times: #{@waiting_times}" )
       
       #@duration=property.caOption.to_s.split(":").size()*2*@wait_after_change+@wait_after_start
       @duration=@wait_after_start
       for k in 0..(property.caOption.to_s.split(":").size()-1)
	  @duration=@duration+@waiting_times[k%@waiting_times.size()]*2
       end
       info("Experiment is going to last for more than #{Integer(@duration/60)} minutes.")
    end
    
    i=0
    #determine the traffic load between each sender-receiver couple
    senders.each do |sender|
      receivers.each do |receiver|	
	@flows.PushFlows(LoadPlanner.new(@demands[i],@duration,sender,receiver).GetFlows())
	if (property.biflow.to_s=="yes")
	  	@flows.PushFlows(LoadPlanner.new(@demands[i],@duration,receiver,sender).GetFlows())
	end
	i=i+1
      end
    end
    
    @caagentsApps=Orbit::ApplicationContainer.new
    @stack=@orbit.GetRoutingStack().class.to_s
    if (@stack!="OrbitLayer25" and @stack!="OrbitOlsr")
      InstallCAAgents()
    end
    
    InstallCAServer()
    
    #install routing table logger
    if (@stack=="OrbitOlsr")
      rt=RoutingTableLoggerHelper.new(@orbit,"Linux")
    elsif  (@stack=="OrbitLayer25")
      rt=RoutingTableLoggerHelper.new(@orbit,"Layer25")
    else
      $stderr.puts("no routing logging available for #{@stack}")
    end
      
    
    @rtloggers=Orbit::ApplicationContainer.new
    
    if (rt!=nil)
      @orbit.GetNodes().each do |node|
	@rtloggers.Add(rt.Install(node.id))
      end
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
  
  def FindITGRecv(receiver, proto)
    @receiverApps.apps.each do |app|
      if app.node==receiver and  app.GetSigChannelPort()==@mapProtocols[proto]
	return app
      end
    end
    return nil
  end
  
  def InstallCAAgents
    
    nodes=@orbit.GetNodes()
    interfaces=@orbit.GetInterfaces()
    
    setFlowrates=(@stack=="OrbitLayer25")
    changeChannels=(@orbit.GetEnv()!="MYXEN")
    
    caagentHelper=CaagentHelper.new(interfaces, "255.255.255.255", "mesh", setFlowrates, changeChannels, @orbit)
    
    nodes.each do |node|
      if node.type=="R"
	@caagentsApps.Add(caagentHelper.Install(node.id))
      end
    end
    
  end
  
  def InstallCAServer
    gateways=""
    
    gats=@orbit.GetGateways()
    aggs=@orbit.GetAggregators()
    
    gats.each do |gw|
      gateways="#{gateways}#{@orbit.GetIpFromId(gw.id)},"
    end
    gateways.chomp!(",")
	                       
    aggregators=""
    aggs.each do |ag|
      aggregators="#{aggregators}#{@orbit.GetIpFromId(ag.id)},"
    end
    aggregators.chomp!(",") 
    
    #support for the installation of the CAServer on an external node if property.caserver is set
    #property must have the following format [node.xpos,node.ypos
    if (property.caserver.to_s!="")
	caserver_str=property.caserver.to_s
	@caserver_node=@orbit.AddNode("F", Integer(caserver_str.split(",")[0]), Integer(caserver_str.split(",")[1]), 0)
    else
	@caserver_node=gats[0]
    end
  
    #we need to keep the information about the node to which the caserver node will be connected
    @caserver_id=@caserver_node.id

    #node of the WMN which acts as gateway for the Caserver (can be the same node which
    #hosts the CAserver)
    @receiver=gats[0]

    info("Installing caserver on node #{@caserver_id}")
    caserverHelper = CAServerHelper.new(aggregators, gateways, @orbit.GetIpFromId(gats[0].id), @orbit.GetChannels(), @orbit.GetInitialChs(), @orbit)
    @caserver=caserverHelper.Install(@caserver_id)

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
	    @orbit.RunOnNode(@caserver_node,"ifconfig #{@orbit.GetControlInterface}:1 192.168.7.#{@caserver_node.id}/24")
	    #@orbit.Node(@receiver.id).net.e0.up
	    #@orbit.Node(@receiver.id).net.e0.ip="192.168.7.#{@receiver.id}/24"
	    @orbit.RunOnNode(@receiver,"ifconfig #{@orbit.GetControlInterface}:1 192.168.7.#{@receiver.id}/24")
	    
	    #add a routing rule to the external node to reach the mesh network through receivers[0]	
	    #The control network is used to make the link
	    @orbit.RunOnNode(@caserver_node,"ip route del to #{@orbit.GetSubnet}")
	    @orbit.RunOnNode(@caserver_node,"ip route add to #{@orbit.GetSubnet} via 192.168.7.#{@receiver.id}")
	    
	    #@orbit.Node(@caserver_id).exec("ip route add to #{@orbit.GetSubnet} via #{@orbit.GetControlIp(@receiver)}")


    	    #add a routing rule to mesh nodes to reach the externel node through @receivers[0]
    	    @orbit.GetNodes().each do |n|
		if (n.id!=@receiver.id)
	    	    	@orbit.RunOnNode(n, "ip route del to 192.168.7.#{@caserver_node.id} ")
	    	    	@orbit.RunOnNode(n, "ip route add to 192.168.7.#{@caserver_node.id} via #{@orbit.GetIpFromId(@receiver.id)} ")
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
    
    #enable arp_filtering
      @orbit.GetNodes().each do |node|
	if property.arpFilter.to_s=="yes"
	  @orbit.Log("Enabling arp_ignore (==1) on node #{node.id}")
	  @orbit.RunOnNode(node,"sysctl -w net.ipv4.conf.all.arp_ignore=1")
	else
	  @orbit.Log("Disabling arp_ignore (==0) on node #{node.id}")
	  @orbit.RunOnNode(node, "sysctl -w net.ipv4.conf.all.arp_ignore=0")
	end
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

    if (@initial_demands!=nil)
      initial_demands=@initial_demands
    else
      initial_demands=GetInitialDemands(@flows)
    end
      
    puts "Initial demands:"
    initial_demands.each do |dm|
      puts "#{dm} "
    end
    

    @orbit.WriteInLogs("Starting first channel assignment")
    
    #first channel assignment - before the traffic generation starts
    if (@assign)
    	@caserver.SetAlgo(property.initialAlgo.to_s)
	if (property.initialAlgo.to_s=="FCPRA")
	  @caserver.OverrideNumChannels(Integer(property.initialAlgoOption.to_s))
	  @caserver.AssignChannels(initial_demands)
	else
	  @caserver.AssignChannels(initial_demands, property.initialAlgoOption.to_s)
	end
	
    	info("Wait the channel assignment server to complete the first assignment")
    	wait(60)
    end

    wait(10+@extraDelay)

    if (@orbit.class.to_s=="OrbitLayer25" and property.freezeTopology.to_s=="yes")
	info("Freezing topology")
	@orbit.FreezeTopology()
    end
    
    nn=Array.new
    @orbit.GetNodes().each do |node|
      nn << node
    end
    
    if property.avoidTcpRst.to_s=="yes"
	#if property.biflow.to_s=="yes" 
	#  @orbit.GetReceivers().each do |node|
	#    nn << node
	#  end
	#end
	nn.each do |node|
	  @orbit.RunOnNode(node,"iptables -A INPUT -p tcp --tcp-flags RST RST -j DROP")
	end
    end
    
  

    
 
      
    info("Starting rt loggers")
    @rtloggers.StartAll

    @orbit.WriteInLogs("Starting traffic generation")
    
    #start the flows
    info ("Starting traffic generation")
	
    #set the channel assignment algo to be used for reassignments (either FCPRA or MCVRA)
    @caserver.SetAlgo(@algo)

    #Used to store demands for Channel Assignment
    new_demands=Array.new

    while (@flows.FlowsLeft()>0)

	 flow=@flows.NextFlow
	  
	 if (flow.start!=currTime)
	   interval=flow.start-currTime
	   wait(interval/2)
	   
  	   if (@assign)
           	info("Reassigning channels.")
		if @algo=="MA"
		    @caserver.ReassignChannels(new_demands, property.caOption.to_s)
		else
		    @caserver.ReassignChannels(new_demands, @maxChannelChanges)
		end
	    end	   

	   wait(interval/2)
	   info("Changing network load")
	   currTime=flow.start
	
	   #reset the new_demands array (it is going to be populated)
	   new_demands.clear
	 end
	 
	 #start a new flow through an itgManager; the flow automatically stops.
	 if (flow.bitrate>0)
	  #itgMan=FindITGManager(flow.sender.id)
	  
	  @protocols.each do |proto|
	    info("Starting a flow from #{flow.sender.id} to #{flow.receiver.id}, protocol #{proto}, at #{flow.bitrate} kbps")
    	    itgRecv=FindITGRecv(flow.receiver.id, proto)
	    cmd=MakeDITGCmdLine(flow, itgRecv, 500, proto)
	    logF="/tmp/itgSenderLog-#{proto}-#{flow.sender.id}-#{flow.receiver.id}"
	    @orbit.RunOnNode(flow.sender, "#{cmd} >#{logF} 2>&1")
	  end
	  
	    new_demands << flow.GetBitrateMbits
	 end
    end
    
    if property.caOption.to_s.include?(":")
      
	 changes=property.caOption.to_s.split(":")
	
	 wait(@wait_after_start)
	 
	 j=0
	 changes.each do |change|
	    
	
	    info("Reassigning channels with rule: #{change}")
	    if @algo=="MA"
	      @caserver.ReassignChannels(new_demands, change)
	    else
	      throw "Multiple changes not supported for #{@algo}!"
	    end
	    
	    #wait(@wait_after_change)
	    wait(@waiting_times[j%@waiting_times.size()])
	    
	    inverted=InvertMAChange(change)
    	    info("Reassigning channels with rule (previous rule inverted): #{inverted}")
	    @caserver.ReassignChannels(new_demands, inverted)
	    
	    #wait(@wait_after_change)
	    wait(@waiting_times[j%@waiting_times.size()])
	    j=j+1
	 end
	 
    else
    
      interval=@duration-currTime
      t=25
      wait(t)
      if (@assign)
	  info("Reassigning channels.")
	  if @algo=="MA"
	    @caserver.ReassignChannels(new_demands, property.caOption.to_s)
	  else
	    @caserver.ReassignChannels(new_demands, @maxChannelChanges)
	  end
      end
      
      #wait for the last flows to conclude
      wait(interval-t)
      
    end
      
      

    
    info("Stopping applications.")
    @rtloggers.StopAll
    @receiverApps.StopAll
    @daemons.StopAll
    @itgManagers.StopAll
    
    if property.avoidTcpRst.to_s=="yes"
	nn.each do |node|
	  @orbit.RunOnNode(node,"iptables -D INPUT -p tcp --tcp-flags RST RST -j DROP")
	end
    end
      
    self.CreateVarFile
     
  end
  
  def InvertMAChange(change)
    
    inverted_change=""
    
    change.split(",").each do |ch|
      single_ch=""
      if (ch!="S")
	nodeid=ch.split("-")[0]
	old_ch=ch.split("-")[1]
	new_ch=ch.split("-")[2]
	inverted_change="#{inverted_change}#{nodeid}-#{new_ch}-#{old_ch},"
      end
    end
    
    return "#{inverted_change}S"
  end
  
  def GetInitialDemands(aggregate)
	demands=Array.new
	currTime=0
	while (aggregate.FlowsLeft()>0 and currTime==0)
		flow=aggregate.NextFlow()
		if (flow.start==0)
			demands << flow.GetBitrateMbits
		else
			currTime=flow.start
		end
	end

	aggregate.Rewind()

	return demands

  end

  def CreateVarFile
	file=File.open("exp-var.sh","w")
	file.puts("CASERVER=\"#{@orbit.NodeName(@caserver_node.x,@caserver_node.y)}\"")
	if (property.biflow.to_s=="yes")
	    file.puts("BIFLOW=\"yes\"")
	end
	file.close
  end


 
end


if __FILE__ == $0

end
