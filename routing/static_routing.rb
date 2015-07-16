require 'core/orbit.rb'
require 'core/routing_stack.rb'




class StaticRouting < RoutingStack
  
  
  
  def initialize(prefix)
    @prefix=prefix
  end
  
  
  
  def InstallStack
    @orbit.GetNodes().each do |node|  
      node.GetInterfaces().each do |ifn| 
	if (ifn.IsWifi()) then
	      address=Address.new("#{@prefix}.#{ifn.GetChannel()}.#{node.GetId()}",24)
	      ifn.AddAddress(address)
	      @orbit.AssignAddress(node, ifn, address)
	end
      end
    end
    
    #do nothing, wired link ip addresses are assigned by Orbit class
    @orbit.GetTopology().GetWiredLinks().each do |link|
	
    end
    
    
  end


  #start the routing stack
  def StartStack
    #puts "StartStack not defined!"
    #exit 1
  end

  
  def GetIpFromId(id)
      
  end
  
  
end