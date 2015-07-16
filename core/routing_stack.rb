require 'core/orbit.rb'

class RoutingStack

  
  def initialize()
    self.DefProperties
    @senderApps = Orbit::ApplicationContainer.new
    @receiverApps = Orbit::ApplicationContainer.new
    @stackApps = Orbit::ApplicationContainer.new
  end

  
  def SetOrbit(orbit)
    @orbit=orbit
    #@nodes=orbit.GetNodes()
    #@senders=orbit.GetSenders()
    #@receivers=orbit.GetReceivers()
  end
  
  #define some properties that can be set from the command line
  def DefProperties
  end
  
  def InstallStack

  end


  #start the routing stack
  def StartStack
    #puts "StartStack not defined!"
    #exit 1
    @rstack.StartStack
  end

  
  def GetIpFromId(id)
      
  end

  #get the subnet used for nodes
  def GetSubnet()
 
  end

  def StartStack

  end
  
  def SetMeshInterface()

  end
  
  def SetMtu(node)
     
  end
  
  def StopStack

  end
  
  def GetStackStats(filename)

  end
  
  def InstallTcpdump(tcpdumpapps)

  end
  
  def WriteInLogs(message)
    
  end
  
  #transitional function - no need to implement
  def Node(node_id)
    return @orbit.Node(node_id)
  end
  
  def GetNodes()
    return @orbit.GetNodes()
  end
  
  
end