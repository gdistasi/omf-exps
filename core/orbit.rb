require "./utils.rb"
require "./topology.rb"
require "./tcpdump-helper.rb"

require 'omf-expctl/handlerCommands.rb'
require 'omf-expctl/nodeHandler'
require 'test/unit'
require 'set'

#to get the control ip
require 'open-uri'
require 'pp'


# This class implements an API that serves the purpose of interacting with the ORBIT testbed.

class Orbit
  
  #include Commands from EC
  include OMF::EC::Commands
  
  attr_accessor :channels
  
  def initialize()

    @interfaces=Array.new
        
    @range=1
  
    #true if the radios have to be configured by OMF
    @setradios=false
    
    #rate == 0 => autorate
    @rate=0
    
    DefProperties()
        
    #testbed used (the name of nodes changes depending on the OMF testbed which is used - see NodeName)
    @env=property.env.to_s

    
    #channels to be used
    #@channels = [36, 64, 48, 1, 11, 6]
    #@channels  = [ 36, 40, 44, 48, 52, 56, 60 ]
    #@channels  = [ 36,  44, 52, 60 ]
    
    
    if (property.channels.to_s!="")
	@channels = Array.new
	property.channels.to_s.split(",").each do |ch|
	  @channels << Integer(ch)
	end
    else
      @channels = [ 36, 44, 149, 157, 165, 1, 11 ]
    
      if GetEnv()=="NEPTUNE"
	@channels = [ 1, 6, 11, 4, 8 ]
      end
    end

    #tool to be used by omf to enforce the topology - default to iptable
    @topotool="mackill"

    @createLinksFile=true
    @linksFile="links"

    #used to assign a unik id to each node
    @lastId=0

    #group of nodes external to the wireless mesh network
    @ext_nodes=Array.new

    @stabilizeDelay=200
    if (property.stabilizeDelay.to_s!="")
	@stabilizeDelay=property.stabilizeDelay
    end

    #property which specify the initial channel to assign to interfaces (comma separated list)
    if property.initialChannels.to_s!=""
	@initialChannels=Array.new
	property.initialChannels.to_s.split(",").each do |ch| 	 	
		@initialChannels << ch
    	end
    end

    if property.mdebug.to_s!=""
	@debug=true
    else
	@debug=false
    end
    
    @aggregators = Array.new
    @gateways = Array.new
    
    
    if (property.env.to_s.include?("ORBIT") or property.env.to_s=="NEPTUNE" or property.env.to_s=="WILEE")
	AddInterface(Orbit::Interface.new("wlan0","WifiAdhoc"))
	AddInterface(Orbit::Interface.new("wlan1","WifiAdhoc"))
    else
	AddInterface(Orbit::Interface.new("eth0","Ether"))
	AddInterface(Orbit::Interface.new("eth2","Ether"))
    end

    #delete old files
    if (File.exists?("orbit-var.sh"))
      File.delete("orbit-var.sh")	
    end
    
    if File.exists?("exp-var.sh")   
       File.delete("exp-var.sh")
    end
    
  end
  
  #set the regulatory domain for WiFi interfaces
  def SetReg()
      if (@env=="ORBIT")
	allGroups.exec("iw reg set US")
      end
  end
  
  def SetChannels(channels)
    @channels=channels
  end

  def log(msg)
    info(msg)
  end
  
  def GetEnv
    return @env
  end
  
  def GetChannels()
    return @channels
  end

  #define some properties that can be set from the command line
  def DefProperties
    defProperty('env', 'ORBIT', "testbed to be used: ORBIT, NEPTUNE")
    defProperty('initialChannels', '', "initial channels to be used on all the nodes")
    defProperty('mdebug', '', "set to yes if you want to enable debug (currently only for l2r)")
    defProperty('stats', '', "number of seconds between each collection of statistics. 0 to avoid at all collecting statistics.")
    defProperty('setAp', '', "IBSS id to set on interfaces in ad-hoc mode: the following command is called: iwconfig <interface> ap <value_given>")
    defProperty('startTcpdump', 'no', "set to yes to have Tcpdump started on nodes")
    defProperty('channels', nil, "comma separated list of channels to use")
  end
  
  #Set to yes if this class has to set the radios (in case the radios are WiFi)
  def SetRadios(enable)
      @setradios=enable
  end
  
  #Set the tool to use to enforce the topology among: [iptable|mackill]
  def SetTopoTool(tool)
    @topotool=tool
  end
  
  def SetRate(rate)
    @rate=rate
  end
  
  def GetRate()
    @rate
  end
  
  def SetPower(power)
    @power=power
  end
  
  def GetInterfaces
    @interfaces
  end
  
  def Debug?()
    @debug
  end
  
  #used to log messages in the routing daemons log files
  def WriteInLogs(message)
      @rstack.WriteInLogs(message)
  end
  
  def Log(message)
    WriteInLogs(message)
  end
  
  def SetChannelsAndRate(node, channels=@channels)
	i=0
	
     	node.GetInterfaces().each do |ifn|
  
		if (@imposed_chs!=nil)
		  ch=@channels[@imposed_chs[i]]
	    	else  
		  if (i==0)
		    ch=@channels[0]
		  else
		    ch=@channels[i]
		  end
	    	end
	    
		if (@setradios and ifn.IsWifi())
		  
		    @orbit.GetGroupInterface(node, ifn).channel="#{ch}"
		    
		    if (@rate!=0)
			  @orbit.GetGroupInterface(node, ifn).rate="#{@rate}"
		    end

		                
		    #Set IBSS if SetAp option is set - after the interface is created
		    if (property.setAp.to_s!="")
		      @orbit.GetGroupInterface(node, ifn).ap=property.setAp.to_s
		    end
		    
		    i=i+1
		end
		
		#self.GetGroupInterface(node, ifn).up
		
		
	end
  end
  
  
  #install the routing stack
  def InstallStack
    if (@rstack==nil)
      puts "InstallStack not defined!"
      exit 1
    else
      @rstack.InstallStack
    end
  end
  
  #get the ip address relative to a certain id
  def GetIpFromId(id)
      #puts "Error. GetIpFromId not defined"
      #exit 1
      return @rstack.GetIpFromId(id)
  end

  #get the subnet used for nodes
  def GetSubnet()
     # puts "Error. GetSubnet not defined"
     # exit 1
    return @rstack.GetSubnet()
  end
  

  #not used anymore - to remove
  def StartStackStatCollection
	if (property.stats.to_s!="")
		@stopCollection=false		
		interval=property.stats
		if (interval!=0)
			Thread.new {
				while (@stopCollection!=true)
					puts "Collecting stats."
					GetStackStats("stack-stats-#{Time.now}")
					puts "Next statistics. Sleeping #{interval} seconds"
					Thread.sleep(interval)					
				end
				exit(0)			
			}
		end
	end

  end
  
  #start the routing stack
  def StopStack
    #puts "StopStack not defined!"
    #exit 1
    @rstack.StopStack
  end
  
  def AddRoutingRule(to, gateway)
    @rstack.AddRoutingRule(to, gateway)  
  end

  #set the desired transmission range - default to 0
  def SetRange(range)
    @range=range
  end
  
  def FindNode(node_id)
    node=nil
    
    @nodes.each do |n|
      if n.id==node_id
	node=n
      end
    end
    
    @endHosts.each do |n|
      if n.id==node_id
	node=n
      end
    end
    return node
    
  end

  #Set the topo to be used in the experiment
  def UseTopo(topo)
	#get nodes created by the Topology class
	@nodes=topo.nodes

	@senders=topo.senders
	@receivers=topo.receivers
	@endHosts=topo.endHosts
	@links=topo.links
	@wired_links=topo.wired_links
	
	@topology=topo

	#define the topology in OMF
      	defTopology('testbed') do |t|   
    
		@nodes.each{ |node|
                    puts "Adding node"
                    t.addNode("node#{node.id}", NodeName(node.x,node.y) )
        	}
		@links.each do |link|
		        puts "Adding link"
			t.addLink("node#{link.from.id}", "node#{link.to.id}", {:emulationTool => @topotool, :state => :up} )
		end
		topo.LinksToRemove.each do |link|
		        puts "Removing link"
			t.addLink("node#{link.from.id}", "node#{link.to.id}", {:emulationTool => @topotool, :state => :down} )
		end

		# The filename is: 'ID-Graph.dot' where 'ID' is this experiment ID
		#t.saveGraphToFile()

	end	
	
	
	topo.receivers.each do |n|
	  
	  if n.type=="G"
	    @gateways << n
	  end
	end

	topo.senders.each do |n|
	 
	  if n.type=="A"
	     @aggregators << n
	  end
	  
	end
	
	@wired_links.each do |wlink|
	                             
#	  @caserver_node.id => wlink.from.id
#	  @receiver.id => wlink.to.id
	    #set the ip address of the two interfaces used to realize the link
	    #@orbit.Node(@caserver_node.id).net.e0.up
	    #@orbit.Node(@caserver_node.id).net.e0.ip="192.168.7.#{@caserver_node.id}/24"
	    Node(wlink.from.id).exec("ip addr add 192.168.#{wlink.to.id}.1/24 dev #{GetDataInterface()}; ifconfig #{GetDataInterface()} up")
	    wlink.from.AddAddress("192.168.#{wlink.to.id}.1", 24, GetDataInterface())
	    Node(wlink.from.id).exec("sysctl -w net.ipv4.conf.all.accept_redirects=0")
	    #@orbit.Node(@receiver.id).net.e0.up
	    #@orbit.Node(@receiver.id).net.e0.ip="192.168.7.#{@receiver.id}/24"
	    Node(wlink.to.id).exec("ip addr add 192.168.#{wlink.to.id}.2/24 dev #{GetDataInterface()}; ifconfig #{GetDataInterface()} up ")
    	    wlink.to.AddAddress("192.168.#{wlink.to.id}.2", 24, GetDataInterface())

	    
	    #add a routing rule to the external node to reach the mesh network through receivers[0]	
	    #The control network is used to make the link
	    Node(wlink.from.id).exec("ip route del default")
	    Node(wlink.from.id).exec("ip route add default via 192.168.#{wlink.to.id}.2 dev #{GetDataInterface()}")
	    
	    #@orbit.Node(@caserver_id).exec("ip route add to #{@orbit.GetSubnet} via #{@orbit.GetControlIp(@receiver)}")


    	    #add a routing rule to mesh nodes to reach the externel node through @receivers[0]
    	    #@orbit.GetEndHosts().each do |n|
		#if (n.id!=wlink.to.id)
	    	 #   	@orbit.Node(n.id).exec("ip route del to 192.168.#{wlink.from.id}.1 ")
	    	 #   	@orbit.Node(n.id).exec("ip route add to 192.168.#{wlink.from.id}.1 via #{@orbit.GetIpFromId(wlink.to.id)} ")
			#@orbit.Node(n.id).exec("ip route add to #{@orbip(@caserver_node)} via #{@orbit.GetIpFromId(wlink.to.it)} ")
			#@orbit.Node(n.id).net.e0.route({:op => 'add', :net => '10.42.0.0', 
                	#:gw => '10.40.0.20', :mask => '255.255.0.0'}
		#end
	    #end
	    
	    #Inform the routing daemon about the link to the external node
	    AddRoutingRule("192.168.#{wlink.to.id}.1", GetIpFromId(wlink.to.id))
	  
	    if (wlink.from.type=="S")
	      @aggregators << wlink.to
	    elsif (wlink.from.type=="D")
	      @gateways << wlink.to
	    end
	end

  end
  
  #Enforce topology: mac filtering to be employed
  def EnforceTopology
      #enforce topology on all the (potential) wired and wireless interfaces
      #onEvent(:ALL_INTERFACE_UP) do |event|
	info("Enforcing topology.")

	@nodes.each do |node|
	  node.GetInterfaces().each do |ifn|
	    self.GetAllGroupsInterface(ifn).enforce_link =  {:topology => 'testbed', :method => @topotool }
	  end
	end
	  
    #end
  end

  #Add a node to the experiment
  def AddNode(type, xpos, ypos, numRadios )
	node = Node.new(@lastId, type, xpos, ypos, numRadios )
	@lastId=@lastId+1
	#let OMF know we have created this node
	DefineGroup(node)
	return node
  end

  #Add nodes to an experiment
  def AddNodes(nodes)
	nodes.each do |n|
		n.id=@lastId
		DefineGroup(n)
		@lastId=@lastId+1
	end
	return nodes
  end
  
  def NodeName(node)
      return NodeName(node.x,node.y)
  end
  
  #Get the node name from the [x,y] coordinate
  def NodeName(x,y)
      if (@env=="MYXEN")
	name = "omf-virtual-node-#{y}"
      elsif (@env=="ORBIT")
	name = "node#{x}-#{y}.grid.orbit-lab.org"
      elsif (@env=="NITOS")
	str = "#{y}"
	while (str.size<3)
	  str="0#{str}"
	end
	name = "omf.nitos.node#{str}"
      elsif (@env.include?("ORBIT_SB"))
        sandboxNum=@env[-1,1]
	name = "node#{x}-#{y}.sb#{sandboxNum}.orbit-lab.org"
      elsif (@env=="WILEE")
	name = "n_#{y}"
      elsif (@env=="NEPTUNE")
	str = "#{y}"
	#while (str.size<2)
	#  str="0#{str}"
	#end
	name = "Node#{str}"
      else
	raise "NodeName is not supported in #{GetEnv()}"
      end
	
      return name
  end

  #Function to get the control ip of nodes  
  def GetControlIp(node)
	if (@env=="ORBIT")
		"10.10.#{node.x}.#{node.y}"
	elsif (@env=="MYXEN")
		"192.168.8.#{node.y+10}"
	elsif (@env=="NEPTUNE")
	  
	    nodeName = NodeName(node.x,node.y)
	    url = "http://tk-virtual:5053/inventory/getControlIP?hrn=#{nodeName}&domain=#{OConfig.domain}"
	    #reply = NodeHandler.service_call(url, "Can't get Control IP for '#{nodeName}'")
	    
	    open(url) do |f|
		  f.each do |line|
		    if line.include?("CONTROL_IP") then
		        return line.gsub(/<.?CONTROL_IP>/,"")
		    end
		  end
	    end
	    	    
	elsif (@env=="NEPTUNE_OLD")
	  
		if (NodeName(node.x, node.y)=="WIFI-Node01")
		    "192.168.74.238"
		elsif (NodeName(node.x, node.y)=="WIFI-Node02")
		    "192.168.74.237"
		end

	else
		$stderr.print("Don't know the control ip for the testbed #{@env}. Exiting.\n")
		exit(1)
	end
  end

  def GetDataInterface()
    if (@env=="ORBIT")
      return "eth0"
    elsif (@env=="NEPTUNE")
      return "eth1"
    else
      return "#{GetControlInterface()}"
    end
  end
  
  #function the get the control interface of nodes
  def GetControlInterface()
	if (@env.include?("ORBIT"))
		"eth1"
	elsif (@env=="MYXEN")
		"eth1"
	elsif (@env=="WILEE")
		"eth1"
	elsif (@env=="NEPTUNE")
		"eth0"
	else
		$stderr.print("Don't know the control interface for the testbed #{@env}. Exiting.\n")
		exit(1)
	end
  end

 
  #Set the channels to be assigned during the nodes setup
  #if this initial set is not given, only the first two interfaces are setup
  #with @channels[0] and @channels[1];
  #the input parameter is an array which contains the indexes of the
  #channels to use
  def SetInitialChs(channels)
    @initialChannels=channels
  end

  def GetInitialChs()
    @initialChannels
  end
  
  #Get a reference to an OMF Node object
  def Node(node_id)
    return group("node#{node_id}")
  end

  #Define a group associated to this single node
  #each node is associated with a group whose name is "node#{node.id}"
  #this group will be used to refer to the node
  def DefineGroup(node)
    defGroup("node#{node.id}",  NodeName(node.x,node.y))
  end
  
  #cleaning up - killall to be moved in the respective application classes
  def CleanUp
	allGroups.exec("killall ITGRecv >/dev/null 2>&1;")
	allGroups.exec("killall ITGManager >/dev/null 2>&1; killall ITGSend >/dev/null 2>&1;")             
	#set the interfaces down
        @nodes.each do |node|
		if node.GetType()=="R"
		 @interfaces.each do |ifn|
		    self.GetGroupInterface(node, ifn).down
		  end
		end
		
		node.GetAddresses().each do |add|
		  info("Deleting address #{add.ip} from interface #{add.interface} on node #{node.id}")
		  Node(node.id).exec("ip addr del #{add.ip}/#{add.netmask} dev #{add.interface}")
		end
	end
  end

  def SetMode(node)
    
     	node.GetInterfaces().each do |ifn|
            info("Configuring interface #{ifn.name}")
	    if (@setradios and ifn.IsWifi())
		if (ifn.GetMode()=="adhoc")
		  self.GetGroupInterface(node,ifn).mode="adhoc"
		elsif (ifn.GetMode())="master")
		  self.GetGroupInterface(node,ifn).mode="master"
		end  

		self.GetGroupInterface(node,ifn).type="a"
	    end
	end
  end
  
  def SetEssid(node)
     	node.GetInterfaces().each do |ifn|
		  #info("Configuring interface #{ifn.name}")
	    if (@setradios and ifn.IsWifi())
		self.GetGroupInterface(node,ifn).essid="meshnet"
	    end
	end
  end
  
  #set the mtu of the interfaces
  def SetMtu(node)
      @rstack.SetMtu(node)
  end
  
  def SetChannelsAndRate(node, channels=@channels)
	i=0
	
     	node.GetInterfaces().each do |ifn|
  
		if (@imposed_chs!=nil)
		  ch=channels[@imposed_chs[i]]
	    	else  
		  if (i==0)
		    ch=channels[0]
		  else
		    ch=channels[i]
		  end
	    	end
	    
		if (@setradios and ifn.IsWifi())
		  
		    self.GetGroupInterface(node, ifn).channel="#{ch}"
		    
		    if (@rate!=0)
			  self.GetGroupInterface(node, ifn).rate="#{@rate}"
		    end

		                
		    #Set IBSS if SetAp option is set - after the interface is created
		    if (property.setAp.to_s!="")
		      self.GetGroupInterface(node, ifn).ap=property.setAp.to_s
		    end
		    
		    i=i+1
		end
		
		#self.GetGroupInterface(node, ifn).up
		
		
	end
  end

  def SetWifiPower(node)
    	
     if (@power!=nil and @setradios)
	node.GetInterfaces().each do |ifn|
	     if ifn.IsWifi()
	      if ifn.type.include?("Atheros")
	        real_name="ath#{ifn.name[-1,1]}"
	      else
	        real_name=ifn.name
	      end
			   
	      Node(node.id).exec("iwconfig #{real_name} txpower #{@power}dbm")
	    end
        end
     end
  end
  
  
  #Set the network interfaces of nodes (the mesh interface is excluded)
  def SetUpNodes
    @nodes.each do |node|

      if node.type=="R" or node.type=="A" or node.type=="G"
      	
	SetMode(node)

	SetChannelsAndRate(node)
	
	SetEssid(node) # after this stage, with omf-5.4 the wlan interface is created.
	
	SetWifiPower(node)

	SetMtu(node)

	SetIp(node)
	
	Node(node.id).exec("sysctl -w net.ipv4.conf.all.send_redirects=0")
	
      end
      #final settings
      #self.GetGroupInterface(node, ifn).txqueuelen="10"
    end
  end
  
  # FIXME orbit requires to assign an ip address to node to get the MAC of the interfaces
  def SetIp(node)
       	node.GetInterfaces().each do |ifn|
	  self.GetGroupInterface(node, ifn).ip="1.1.1.1"
  	  self.GetGroupInterface(node, ifn).up
	end
  end

  def GetStackStats
	#to be override by derived classes
  end
  
  def ECCanServeFiles()
      return false
  end
  
  def GetECAddress()
      if GetEnv()=="ORBIT"
	return  "10.10.0.10"
      elsif GetEnv()=="NEPTUNE"
	return "tk-virtual"
      elsif GetEnv()=="ORBIT_SB1"
	return "10.11.0.10"
      elsif GetEnv()=="NEPTUNE"
	return "192.168.8.200"
      elsif GetEnv()=="WILEE"
	return "192.168.8.200"
      else
	raise "No GetECAddress supported in #{GetEnv()}"
      end
  end
  
  def InstallTcpdump
      @tcpdumpApps=ApplicationContainer.new
      tcpdumpHelper=TcpdumpHelper.new
      @nodes.each do |node|
	if node.type=="R" or node.type=="A" or node.type=="G"
	  node.GetInterfaces().each do |ifn|
	    @tcpdumpApps.Add(tcpdumpHelper.Install(node.id, ifn.name))
	  end
	  ints=Set.new
	  node.GetAddresses().each do |add|
	    ints.add(add.interface)
	  end
	  
	  ints.each do |int|
	    @tcpdumpApps.Add(tcpdumpHelper.Install(node.id, int))
	  end
	  
	elsif node.type=="S" or node.type=="D"
	  @tcpdumpApps.Add(tcpdumpHelper.Install(node.id, GetDataInterface()))
	end
      end
      
      #routing layer specific task
      @rstack.InstallTcpdump(@tcpdumpApps)
  end
  
  #start Tcpdump on the interfaces - the logs go in /tmp/tcpdump-log
  #Started only if the startTcpdump property is set to yes
  def StartTcpdump
      if (property.startTcpdump.to_s=="yes" or property.startTcpdump.to_s=="true" or property.startTcpdump.to_s=="1")
	info("Start Tcpdump apps.")
	@tcpdumpApps.StartAll
      end
   end
  
   def CreateTopoOffOrbit(topo)
      
      if not GetEnv()=="ORBIT"
	raise "CreateTopoOffOrbit does not support #{GetEnv()}"
      end
      
      topoOffFile=File.open("topoOff","w")
  
      (1..20).each do |x|
	(1..20).each do |y|
	 if not topo.include?(x,y) 
	   topoOffFile.write("#{NodeName(x,y)},")
	 end
	end
      end
      
      topoOffFile.close
     
   end
   
   #settings to be performed after the mesh stack has been started (e.g. setting the ip address on the mesh interface)
   def SetMeshInterface()
      @rstack.SetMeshInterface()
   end
   
  #Run the experiment - exp must be an object of a subclass of Orbit:Exp
  def RunExperiment(exp)

    
    self.SetReg
    self.SetUpNodes
    self.InstallStack
    
    exp.SetOrbit(self)
    
    #install experiment applications
    exp.InstallApplications
    
    self.InstallTcpdump
    
    #Experiment specific setup for nodes
    exp.SetUpNodes
    
    onEvent(:ALL_UP_AND_INSTALLED) do |event|
	info "Starting stack." 
	self.StartStack
	info("Waiting for the network stack to be started")
	wait(15)

	self.SetMeshInterface()
	
	#self.StartStackStatCollection()
	
	#Enforcing topology (we need the stack to be started)
	self.EnforceTopology
	
	info("Waiting the network to stabilize")
	wait(@stabilizeDelay)

	self.StartTcpdump

	# Starting the applications
	info("Starting experiment")
	exp.Start
	
	#if we are not collecting continuosly the statistics, get them at the end of the experiment
	if (property.stats.to_s=="")
		self.GetStackStats
	else
		@stopCollection=true
	end

	self.StopStack

	self.CleanUp
	
	Experiment.done
    end
    
    
    self.CreateVarFile

  end
  
  def GetGateways()
      return @gateways.to_a
  end

  def GetAggregators()
      return @aggregators.to_a
  end
  
  def CreateVarFile
	file=File.open("orbit-var.sh","w")
	file.write("NODES=\"")

	@nodes[0,@nodes.size-1].each do |node|
		file.write("#{NodeName(node.x,node.y)},")
   	end
	lastNode=@nodes[-1]
        file.write("#{NodeName(lastNode.x,lastNode.y)}\"\n")

	
	if (@receivers.size()>0)
	  file.write("GATEWAYS=\"")
	
	  @receivers[0,@receivers.size-1].each do |node|
		file.write("#{NodeName(node.x,node.y)},")
	  end
	  
	  lastNode=@receivers[-1]
	  file.write("#{NodeName(lastNode.x,lastNode.y)}\"\n")
	
	end  
	  

	if (@senders.size()>0)
          file.write("AGGREGATORS=\"")

	  @senders[0,@senders.size-1].each do |node|
		file.write("#{NodeName(node.x,node.y)},")
	
	  end
	  lastNode=@senders[-1]
	  file.write("#{NodeName(lastNode.x,lastNode.y)}\"\n")
	end
	
	file.close
  end
  
  #Add an interface to _all_ nodes
  def AddInterface(interface)
    @interfaces << interface
  end

  def GetNodes()
	@nodes
  end
  
  def GetEndHosts()
      return @endHosts
  end

  #Return the handler to the interface ifn (of all nodes)
  #the equivalent of allGroups.net.#{interface} of OMF
  def GetAllGroupsInterface(ifn)
    
    num=Integer(ifn.name[-1,1])
    
    if (ifn.IsEthernet())
	      if (num==0)
		ret=allGroups.net.e0
	      elsif (num==2)
		ret=allGroups.net.e1
	      else
		 puts "Error. Could not find interface #{ifn.name}"
		 exit 1
	      end
		
    elsif (ifn.IsWifi())
	      if (num==0 or num==2)
		ret=allGroups.net.w0
	      elsif (num==1 or num==3)
		ret=allGroups.net.w1
	      else
		 puts "Error. Could not find interface #{ifn.name}"
		 exit 1
	      end
    else
	      puts "Unkown type for interface #{ifn.name}"
    end
    
    return ret
  
  end
  
  #Same as the previous function but just referred to one node
  def GetGroupInterface(node, ifn)
    
    num=Integer(ifn.name[-1,1])
    
    if (ifn.IsEthernet())
	      if (num==0)
		ret=Node(node.id).net.e0
	      elsif (num==2)
		ret=Node(node.id).net.e1
	      else
		 puts "Error. Could not find interface #{ifn.name}"
		 exit 1
	      end
		
    elsif (ifn.IsWifi())
	      if (num==0 or num==2)
		ret=Node(node.id).net.w0
	      elsif (num==1 or num == 3)
		ret=Node(node.id).net.w1
	      else
		 puts "Error. Could not find interface #{ifn.name}"
		 exit 1
	      end
    else
	      puts "Unkown type for interface #{ifn.name}"
    end
    
    return ret
  
  end

  #Class which identifies an instance of an application
  class Application
     attr_accessor :node

    include OMF::EC::Commands
    
    def initialize(node, name, orbit=nil)
	@node=node
	@name=name
	@orbit=orbit

	#puts "Storing application #{name} on node #{node}"
    end
    
    def StartApplication
	#puts "Starting application #{@name} on node #{@node}"
	group("node#{@node}").startApplication(@name)
    end
    
    def StopApplication
	group("node#{@node}").stopApplication(@name)
    end
    
    def SendMessage(msg)
	group("node#{@node}").sendMessage(@name, msg)
    end
    
  end
  
  #Class which contain several applications
  class ApplicationContainer
      attr_accessor :apps

    
    def initialize()
	@apps=Array.new
    end
    
    def Add(app)
	@apps << app
    end
    
    def each
      return @apps.each
    end
    
    def StartAll
	@apps.each do |app|
	  app.StartApplication
	end
    end
    
    def StopAll
	@apps.each do |app|
	  app.StopApplication
	end
    end
    
  end
  
  class Interface
    attr_accessor :name, :type

    def initialize(name, type)
      @name=name
      @type=type
    end
    
    def IsEthernet()
      return @type=="Ether"
    end
    
    def IsWifi()
      return @type.include?("Wifi")
    end
    
  end
  
  #Basic experiment class that installs and manages applications to be executed
  #it is meant to manage the experiment at the application level.
  #all experiment classes must derive from this
  class Exp 
    
    def SetOrbit(orbit)
      @orbit=orbit
    end
  
    def InstallApplications
      puts "InstallApplications not defined!"
      exit(1)
    end

    def Start
      puts "Start not defined!"
      exit(1)
    end
    
    #set the duration of traffic generation
    def SetDuration(duration)
      @duration=duration
    end
    
    def SetUpNodes
      
    end
 
    
  end
  
end

