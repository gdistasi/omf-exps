
require "routing/static_routing.rb"
require "ch_assignment/static-channel-assignment.rb"
require "traffic/SenderReceiverPattern.rb"
require "aqm/aqm.rb"
require "routing/olsr.rb"

defProperty('duration', 120, "Overall duration in seconds of the experiment")
defProperty('topo', 'topos/topo0', "topology to use")
defProperty('extraDelay', 0, "extra delay before starting assigning channel and start traffic generation")
defProperty('protocol', "TCP", "protocol to use for traffic generation")
defProperty('biflow', "no", "set to yes if you want a flow also in the gateway aggregator direction")
defProperty('demands', "", "comma separated list of initial demands")
defProperty('aqmPolicy', "", "aqm policy to apply to interface")
defProperty('aqmPolicyOptions', "", "option to apply to aqm policy")
defProperty('onFeatures', "", "semicolon separated list of features to apply to interface (e.g. gso)")
defProperty('offFeatures', "", "semicolon separated list of feature to turn off to interface (e.g. gso)")
defProperty('bottleneckRate',"", "rate to apply to bottleneck interface")
defProperty('rate',"", "rate to apply to bottleneck interface")
defProperty('withOlsr',"no", "Set to yes if Olsrd has to manage routing")
defProperty('rttm',"no", "Set to yes if flows have to go to the destinations and then come back at the senders (to measure RTTs)")
defProperty('txqueuelen',"", "Txqueuelen of the bottleneck interface")

    
if (property.withOlsr.to_s=="yes")
  rstack=OrbitOlsr.new("192.168")
else
  rstack=StaticRouting.new("192.168")
end
	
orbit=Orbit.new

orbit.SetRoutingStack(rstack)

#ask orbit to set up the radios
orbit.SetRadios(true)

#pass the topology specification to Orbit that will enforce it
orbit.UseTopo(property.topo)

orbit.SetDefaultTxPower(15)

   
class TestNew < Orbit::Exp

  def initialize(orbit)
    
    #@cassign=StaticChannelAssignment.new(orbit)
    
    if property.demands.to_s=="" then
        demands="10000"
    else
        demands=property.demands.to_s
    end
    
     #@traffic=IncreaseNumFlowsPattern.new(orbit, property.initialDemands, property.protocol, property.numFlows, property.duration, property.biflow.to_s=="yes")
    @traffic=SenderReceiverPattern.new(orbit, demands, property.protocol, property.duration, property.biflow.to_s)
    
    if (property.rttm.to_s=="yes")
      @traffic.TurnRttmOn()
    end
      
    @orbit=orbit
  
  end
  
  def InstallApplications
    @traffic.InstallApplications()
    
    #install routing table logger
    #if (@orbit.GetRoutingStack().class.name=="OrbitOlsr")
    #  rt=RoutingTableLoggerHelper.new(@orbit,"Linux")
    #elsif  (@orbit.GetRoutingStack().class.name=="OrbitLayer25")
    #  rt=RoutingTableLoggerHelper.new(@orbit,"Layer25")
    #else
    #  $stderr.puts("no routing logging available for #{@stack}")
    #end
      
    
    #@rtloggers=Orbit::ApplicationContainer.new
    
    #if (rt!=nil)
    #  @orbit.GetNodes().each do |node|
#	@rtloggers.Add(rt.Install(node.id))
#     end
#    end


    
  end
  
  def EnforceRate(orbit, node, ifn, rate)
    
      r=Integer(rate)
      
      ifn_real_name=@orbit.GetRealName(node, ifn)

      if ifn.IsEthernet or @orbit.GetEnv=="MININET" then
	orbit.RunOnNode(node, "tc qdisc replace dev #{ifn_real_name} handle 8000: root tbf burst 14999 rate #{r}kbit latency 1.0ms")
      elsif ifn.IsWifi then
	orbit.EnforceRate(node, ifn, rate)
      end

  end	
  
  def Start
    #@cassign.Start
    #info("Wait for channel assignment to complete")
    #wait(10)
    
   
    if (property.withOlsr.to_s!="yes")
      #routing/static_routing.rb is not complete - it should populate the routing table of nodes according to the topology of the network described by the xml file while at the moment it just assigns ip addresses.
      nodes=@orbit.GetNodes
      @orbit.RunOnNode(nodes[0], "ip route replace default via #{nodes[1].GetAddresses()[0].to_s}")
      @orbit.RunOnNode(nodes[2], "ip route replace default via #{nodes[1].GetAddresses()[1].to_s}")
      @orbit.RunOnNode(nodes[1], "echo 1 >/proc/sys/net/ipv4/conf/all/forwarding")
    end
    
    if (property.extraDelay!=0)
      info("Waiting additional #{property.extraDelay}s as requested.")
      wait(property.extraDelay)
    end
    
    bottNode = @orbit.GetNodesWithAttribute("bottleneck")[0]
    ifn = bottNode.GetInterfaces()[0]
    
    ifn_real_name=@orbit.GetRealName(bottNode,ifn)	
    
    rateSet=false
    bottleneckRateSet=false
    
    @orbit.AddLogFile(bottNode, "/tmp/ethToolStats")
    @orbit.AddLogFile(bottNode, "/tmp/tcStats")
    
    
    
    if (property.rate.to_s!="") then
       rateSet=true
       nodes=@orbit.GetNodes()
       nodes.each do |node|
          node.GetInterfaces().each do |int|
             if int.class.to_s=="WifiInterface" then
                EnforceRate(@orbit, node, int,  property.rate.to_s)  
             end
          end
       end
    end
    
    
    if (property.bottleneckRate.to_s!="")
        EnforceRate(@orbit,bottNode, ifn, property.bottleneckRate.to_s)
        bottleneckRate=true
    end
    
    if (property.txqueuelen.to_s!="")then
        @orbit.RunOnNode(bottNode, "ifconfig #{ifn_real_name} txqueuelen #{property.txqueuelen.to_s}")
    end
    
    
  if (property.aqmPolicy.to_s!="") then
        
      
       
    
       nodes.each do |node|
          @orbit.RunOnNode(node, "modprobe sch_#{property.aqmPolicy.to_s}") unless property.aqmPolicy.to_s=="FQ_MAC"
       end
        
      conf=AqmConfigurator.new(property.aqmPolicy.to_s,property.aqmPolicyOptions.to_s)
      #@orbit.RunOnNode(bottNode, conf.ResetCmd(ifn_real_name))
      
      if @orbit.GetEnv()=="MININET" then
          parent=8000
          
          if not (rateSet or bottleneckRateSet) then
             abort("It is necessary to set rate or bottleneck rate in MININET Environment!") 
          end
          
      else
         parent=nil 
      end
      
      @orbit.RunOnNode(bottNode, conf.GetCmd(ifn_real_name, parent))
    end

    
    iConf=InterfaceConfigurator.new
    property.onFeatures.to_s.split(",").each do |f|
            @orbit.RunOnNode(bottNode, iConf.GetCmdFeatureOn(f,ifn_real_name))
    end
    property.offFeatures.to_s.split(",").each do |f|
            @orbit.RunOnNode(bottNode, iConf.GetCmdFeatureOff(f,ifn_real_name))
    end
        
    
    @orbit.RunOnNode(bottNode, "ethtool -k #{ifn_real_name} > /tmp/ethToolStats 2>&1")
    
    #@rtloggers.Start
    @traffic.Start
    wait(property.duration)
    
    @orbit.RunOnNode(bottNode, "tc -s qdisc show dev #{ifn_real_name} > /tmp/tcStats 2>&1")
    
  end
  
end


   
exp=TestNew.new(orbit)
exp.SetDuration(property.duration)

orbit.RunExperiment(exp)


