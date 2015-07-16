

# Assign the channels to network nodes' interfaces based on the given initialDemands and using the initialAlgo and numChannels.
# Supported algorithms are FCPRA and OneChannel.
class ChannelAssigner 

  def initialize(orbit, initialDemands, initialAlgo, caOption, caserver_str=nil)
    @initialDemands=initialDemands
    @initialAlgo=initialAlgo
    @caOption=caOption
    @orbit=orbit
    @caserver_str=caserver_str

    if (initialDemands.to_s!="")
      @initial_demands=Array.new
      initialDemands.to_s.split(",").each do |demand|
	@initial_demands << Float(demand)
      end
    end


  end
  
  
  def InstallApplications
    @caagentsApps=Orbit::ApplicationContainer.new
    @stack=@orbit.GetRoutingStack().class.to_s
    if (@stack!="OrbitLayer25" and @stack!="OrbitOlsr")
      InstallCAAgents()
    end
    
    InstallCAServer()

  end


  def InstallCAAgents
    
    nodes=@orbit.GetNodes()
    interfaces=@orbit.GetInterfaces()
    
    setFlowrates=(@stack=="OrbitLayer25")
    changeChannels=(@orbit.GetEnv()!="MYXEN")
    
    caagentHelper=CaagentHelper.new(interfaces, "255.255.255.255", "mesh", setFlowrates, changeChannels)
    
    nodes.each do |node|
      @caagentsApps.Add(caagentHelper.Install(node.id))
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
    if (@caserver_str!=nil)
	@caserver_node=@orbit.AddNode("F", Integer(@caserver_str.split(",")[0]), Integer(@caserver_str.split(",")[1]), 0)
    else
	@caserver_node=gats[0]
	puts @caserver_node
    end
  
    #we need to keep the information about the node to which the caserver node will be connected
    @caserver_id=@caserver_node.id

    #node of the WMN which acts as gateway for the Caserver (can be the same node which
    #hosts the CAserver)
    @receiver=gats[0]

    info("Installing caserver on node #{@caserver_id}")
    
    puts "GATSS #{gats[0]}"
    
    caserverHelper = CAServerHelper.new(aggregators, gateways, @orbit.GetIpFromId(gats[0].id), @orbit.GetChannels(), @orbit.GetInitialChs(), @orbit)
    @caserver=caserverHelper.Install(@caserver_id)
    
    
    # Add the information about another file to be saved at the end of the experiment
    file=File.open("exp-var.sh","a")
    file.puts("CASERVER=\"#{@orbit.NodeName(@caserver_node.x, @caserver_node.y)}\"")
    file.close 
    
  end


  def Start

    #start caagents
    @caagentsApps.StartAll()
    
    #if the caserver node is installed on an external node set some routing rules
    if (@caserver.to_s!="")
	    #set the ip address of the two interfaces used to realize the link
	    #@orbit.Node(@caserver_node.id).net.e0.up
	    #@orbit.Node(@caserver_node.id).net.e0.ip="192.168.7.#{@caserver_node.id}/24"
	    @orbit.RunOnNode(@caserver_node.id,"ifconfig #{@orbit.GetControlInterface}:1 192.168.7.#{@caserver_node.id}/24")
	    #@orbit.Node(@receiver.id).net.e0.up
	    #@orbit.Node(@receiver.id).net.e0.ip="192.168.7.#{@receiver.id}/24"
	    @orbit.RunOnNode(@receiver.id,"ifconfig #{@orbit.GetControlInterface}:1 192.168.7.#{@receiver.id}/24")
	    

	    #add a routing rule to the external node to reach the mesh network through receivers[0]	
	    #The control network is used to make the link
	    @orbit.RunOnNode(@caserver_id,"ip route del to #{@orbit.GetSubnet}")
	    @orbit.RunOnNode(@caserver_id,"ip route add to #{@orbit.GetSubnet} via 192.168.7.#{@receiver.id}")
	    
	    #@orbit.Node(@caserver_id).exec("ip route add to #{@orbit.GetSubnet} via #{@orbit.GetControlIp(@receiver)}")


    	    #add a routing rule to mesh nodes to reach the externel node through @receivers[0]
    	    @orbit.GetNodes().each do |n|
		if (n.id!=@receiver.id)
	    	    	@orbit.Node(n.id,"ip route del to 192.168.7.#{@caserver_node.id} ")
	    	    	@orbit.Node(n.id,"ip route add to 192.168.7.#{@caserver_node.id} via #{@orbit.GetIpFromId(@receiver.id)} ")
			#@orbit.Node(n.id).exec("ip route add to #{@orbit.GetControlIp(@caserver_node)} via #{@orbit.GetIpFromId(@receiver.id)} ")
			#@orbit.Node(n.id).net.e0.route({:op => 'add', :net => '10.42.0.0', 
                	#:gw => '10.40.0.20', :mask => '255.255.0.0'}
		end
	    end
    end

    info("Wait for CA applications to start")
    wait(5)
    
    info("Starting CAServer")
    @caserver.StartApplication
    
    @caserver.SetAlgo(@initialAlgo)
    @caserver.AssignChannels(@initial_demands,@caOption)


  end

end 



