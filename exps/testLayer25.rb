require "routing/layer25.rb"
require "routing/olsr.rb"
require "routing/80211s.rb"
require "ch_assignment/creass.rb"
require "routing/aodv.rb"
require "routing/batman-adv.rb"

require "ch_assignment/ChannelAssigner.rb"
require "traffic/SenderReceiverPattern.rb"

defProperty('duration', 120, "Overall duration in seconds of the experiment")
defProperty('topo', 'topos/topo0', "topology to use")
defProperty('links', "", "files which contains the links to be defined on the testbed")
defProperty('range', "", "add links equal or shorter than range")
defProperty('demands', "", "comma separated list of initial demands")
defProperty('extraDelay', 0, "extra delay before starting assigning channel and start traffic generation")
defProperty('protocol', "TCP", "protocol to use for traffic generation")
defProperty('biflow', "no", "set to yes if you want a flow also in the gateway aggregator direction")
defProperty('caAlgo', "FCPRA", "Channel Assignment algorithm")
defProperty('caAlgoOption', "2", "option for the channel assignment")
defProperty('stack', "Olsr", "routing stack")
defProperty('caserverId', nil, "Caserver id")


if (property.stack.to_s=="Layer25")
  rstack=OrbitLayer25.new
elsif (property.stack.to_s=="802.11s")
  rstack=Orbit80211s.new
elsif (property.stack.to_s=="Aodv")
  rstack=OrbitAodv.new
elsif (property.stack.to_s=="BatmanAdv")
  rstack=OrbitBatmanAdv.new
else
  rstack=OrbitOlsr.new
end

orbit=Orbit.new

orbit.SetRoutingStack(rstack)

#ask orbit to set up the radios
orbit.SetRadios(true)

#read the topology from the file property.topo
topo=Orbit::Topology.new(property.topo, orbit)

#define the links to be used (enforced via iptable)
if (property.links.to_s!="")
	topo.AddLinksFromFile(property.links.to_s)
end

if (property.range.to_s!="")
	topo.AddLinksInRange(property.range)
end

#pass the topology specification to Orbit that will enforce it
orbit.UseTopo(topo)

orbit.SetPower(15)

class TestNew < Orbit::Exp

  def initialize(orbit)
    
    if (property.caserverId.to_s!="")
     @cassign=ChannelAssigner.new(orbit, property.demands.to_s, property.caAlgo, property.caAlgoOption, property.caserverId.to_s)
    else
     @cassign=ChannelAssigner.new(orbit, property.demands.to_s, property.caAlgo, property.caAlgoOption, nil)
    end
     #@traffic=IncreaseNumFlowsPattern.new(orbit, property.initialDemands, property.protocol, property.numFlows, property.duration, property.biflow.to_s=="yes")
    @traffic=SenderReceiverPattern.new(orbit, property.demands.to_s, property.protocol, property.duration, property.biflow.to_s)
    @orbit=orbit
  
  end
  
  def InstallApplications
    @cassign.InstallApplications()
    @traffic.InstallApplications()
    
    #install routing table logger
    #if (@orbit.GetRoutingStack().class.name=="OrbitOlsr")
    #  rt=RoutingTableLoggerHelper.new(@orbit,"Linux")
    #elsif  (@orbit.GetRoutingStack().class.name=="OrbitLayer25")
    #  rt=RoutingTableLoggerHelper.new(@orbit,"Layer25")
    #else
    #  $stderr.puts("no routing logging available for #{@stack}")
    #end
      
    
    @rtloggers=Orbit::ApplicationContainer.new
    
    #if (rt!=nil)
    #  @orbit.GetNodes().each do |node|
#	@rtloggers.Add(rt.Install(node.id))
#     end
#    end

  end
  
  def Start
    @cassign.Start
    info("Wait for channel assignment to complete")
    wait(60)
    if (property.extraDelay!=0)
      info("Waiting additional #{property.extraDelay}s as requested.")
      wait(property.extraDelay)
    end
    #@rtloggers.Start
    @traffic.Start
    wait(property.duration)
  end
  
end
   
exp=TestNew.new(orbit)
exp.SetDuration(property.duration)
orbit.RunExperiment(exp)

