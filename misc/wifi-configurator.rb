

class WifiConfigurator
  
  def initialize(orbit)
    @orbit=orbit
  end
  
  
  def SetTxBuffer(node, ifn, dim)
    realNameInterface=@orbit.GetRealName(node,ifn) #returns, e.g., wlan0
    
    #use then the orbit class to exec command on the node... 
    #@orbit.RunOnNode(node, "cmd #{realNameInterface}")

  end
  
  
  

end