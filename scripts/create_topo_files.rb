require 'core/orbit.rb'
require 'core/topology.rb'

defProperty('topo', 'topos/topo0', "topology to use")

orbit=Orbit.new

topo=Orbit::Topology.new(property.topo.to_s, orbit, true)

topo.CreateTopoFile

if orbit.GetEnv=="ORBIT"
  orbit.CreateTopoOffOrbit(topo)
  exit(0)
end





