require 'core/orbit.rb'
require 'routing/routing_stack.rb'
require 'core/apps.rb'
require 'utils/click.rb'

class OrbitLayer25 < RoutingStack 
  
  #define some properties that can be set from the command line
  def DefProperties
      super
      defProperty('kernelMode', 'no', "set to yes enable kernel mode")
      defProperty('olsrdebug', 0, "level of debugging output of olsr to be saved")
      defProperty('switchOff', 'no', "set to yes to ask to switch off and then on an interface after a channel change")
      defProperty('aggregation_enabled', 'no', "set to yes to enable aggregation")
      defProperty('aggregation_delay', 0, "aggregation delay when aggregation is enabled")
      defProperty('aggregation_algo', '', "set to enable an aggregation aware algorithm: either AF-L2R or AA-L2R")
      defProperty('weigthFlowrates', 'no', "set to enable the weigthing of flowrates with link quality")
  end
  

 def InstallStack
 
    @receivers=@orbit.GetReceivers()
   
    #install Layer2.5 stack on each node
    stackApp=Layer25Helper.new(@orbit.GetInterfaces(), @orbit)
    stackApp.SetDebug(@debug)
    stackApp.SetOlsrDebug(property.olsrdebug)
    
    if (property.aggregation_enabled.to_s=="1")
	stackApp.EnableAggregation()
	stackApp.SetAggregationDelay(Integer(property.aggregation_delay.to_s))
    end
    
    if (property.aggregation_algo.to_s!="")
	stackApp.SetAggregationAlgo(property.aggregation_algo.to_s)
    end
    
    if (property.weigthFlowrates.to_s!="no")
	stackApp.SetWeigthFlowrates(true)
    else
      	stackApp.SetWeigthFlowrates(false)
    end
    
    
    
    @orbit.GetNodes.each do |node|
      
      if (node.type!="R" and node.type!="A" and node.type!="G")
	next
      end
      
      if (node.id==@receivers[0].id)
	  stackApp.SetGateway(true)
      else
	  stackApp.SetGateway(false)
      end

      if (property.kernelMode.to_s=="yes")
	      stackApp.SetKernelMode(true)
      end
      
      stackApp.FlushRoutingRules()
      @rules.to_a.each do |rule|
	if rule.gateway==GetIpFromId(node.id)
	  stackApp.AddRoutingRule(rule.to,"255.255.255.255")
	end
      end
   

      @stackApps.Add(stackApp.Install(node.id))
      
    end
    
   end
    
 def GetIpFromId(id)
     "192.168.3.#{id+1}"
 end
 
  #get the subnet used for nodes
  def GetSubnet()
      "192.168.3.0/24"
  end  

 def StartStack
    @stackApps.StartAll
    
 end
 
 def SetMeshInterface()
     @orbit.GetNodes.each do |node|
      Node(node.id).exec("/sbin/ifconfig mesh mtu 1500")
     end
 end
 
 def SetMtu(node)
	@orbit.GetInterfaces.each do |ifn|
	    @orbit.GetGroupInterface(node, ifn).mtu="1528"
	end
 end

 def StopStack
    @stackApps.StopAll
 end

 def AddRoutingRule(to, gateway)
    if (@rules==nil)
      @rules = Set.new
    end
    @rules.add(Rule.new(to,gateway))
 end
 
 def GetStackStats(filename="stats-layer25.txt")
	nodes=@orbit.GetNodes()
	click_port=7777
	stat=File.open(filename,"w")
	info("Getting statistics for Layer25 stack.")

	nodes.each do |node|
	  stat.puts("")
	  stat.puts("====================================================================")
	  stat.puts("Node #{GetIpFromId(node.id)}:")
	  sock = TCPSocket.new(@orbit.GetControlIp(node), click_port)
	  sock.puts "read geslinks.get_stats_data_sent\n"

	  #click banner
	  line = sock.gets

	  #click handler OK response
	  line = sock.gets

	  line = sock.gets

	  if (line.include?("DATA"))
		bytes = Integer(line.split(" ")[1])
	  else
		info("Wrong response from node #{GetIpFromId(node.id)}")
		next
	  end

	  bytesRead=0

	  while bytesRead<bytes
		line = sock.gets
		bytesRead = bytesRead + line.size
		stat.write(line)
	  end



	  sock.puts "read flooder.get_topology\n"

	  stat.write("Topology.\n")

	  #click handler OK response
	  line = sock.gets

	  line = sock.gets

	  if (line.include?("DATA"))
		bytes = Integer(line.split(" ")[1])
	  else
		info("Wrong response from node #{GetIpFromId(node.id)}")
		next
	  end

	  stat.write("OK response from flooder.\n")

	  bytesRead=0

	  while bytesRead<bytes
		line = sock.gets
		bytesRead = bytesRead + line.size				
		stat.write(line)
	  end

	  sock.close
      end
	   
      stat.close
  
  end

  def InstallTcpdump(tcpdumpApps)
     tcpdumpHelper=TcpdumpHelper.new
     @orbit.GetNodes.each do |node|   
	tcpdumpApps.Add(tcpdumpHelper.Install(node.id, "mesh"))
     end 
  end
  
  def WriteInLogs(message)
     @orbit.GetNodes.each do |node|

	  click=Click.new(@orbit.GetControlIp(node))
	  click.WriteHandler("geslinks","log_message", message)
	  click.close()
	
      end
  end
  
  def FreezeTopology()
        @orbit.GetNodes.each do |node|

	  click=Click.new(@orbit.GetControlIp(node))
	  click.WriteHandler("flooder","freeze_topology","do")
	  click.close()
	
	end
  end
 
   class Rule
   
   attr_accessor :to, :gateway

   def initialize(to,gateway)
     @to=to
     @gateway=gateway
   end
   
 end
  
end
