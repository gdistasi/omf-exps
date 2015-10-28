
require "routing/static_routing.rb"
require "ch_assignment/static-channel-assignment.rb"
require "traffic/SenderReceiverPattern.rb"

defProperty('duration', 120, "Overall duration in seconds of the experiment")
defProperty('topo', 'topos/topo0', "topology to use")
defProperty('extraDelay', 0, "extra delay before starting assigning channel and start traffic generation")
defProperty('protocol', "TCP", "protocol to use for traffic generation")
defProperty('biflow', "no", "set to yes if you want a flow also in the gateway aggregator direction")
defProperty('demands', "", "comma separated list of initial demands")




rstack=StaticRouting.new("192.168")

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
	demands="100"
    else
        demands=property.demands.to_s
    end
    
     #@traffic=IncreaseNumFlowsPattern.new(orbit, property.initialDemands, property.protocol, property.numFlows, property.duration, property.biflow.to_s=="yes")
    @traffic=SenderReceiverPattern.new(orbit, demands, property.protocol, property.duration, property.biflow.to_s)
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
  
  def Start
    #@cassign.Start
    #info("Wait for channel assignment to complete")
    #wait(10)
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

