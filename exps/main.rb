require "./layer25.rb"
require "./olsr.rb"
require "./80211s.rb"
require "./creass.rb"
require "./aodv.rb"
require "./batman-adv.rb"


defProperty('duration', 120, "Overall duration in seconds of the experiment")
defProperty('topo', 'topos/topo0', "topology to use")
defProperty('range', -1, "range of transmission to force on nodes")
defProperty('links', "", "files which contains the links to be defined on the testbed")
defProperty('stack', "Layer25", "stack to use: Layer25, Olsrd, 802.11s and Aodv")


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
exp=ChannelReassignExp.new(0)

exp.SetDuration(property.duration)

orbit.RunExperiment(exp)

