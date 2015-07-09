require 'core/orbit.rb'


class StaticRouting < RoutingStack
  
  
  
  
  
  def InstallStack
    
    @orbit.GetNodes().each |node| do 
      node.GetInterfaces().each |ifn|
	if (ifn.IsWifi()) then
	      address=Address.new("#{prefix}.#{ifn.GetChannel()}.#{node.GetId()}",24)
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
    @rstack.StartStack
  end

  
  def GetIpFromId(id)
      
  end
  
  
end