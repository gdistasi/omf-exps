require 'core/orbit.rb'
require 'core/apps.rb'


class Orbit80211s < Orbit 
  
  #define some properties that can be set from the command line
  def DefProperties
      super
  end
  
  #no software to install for 802.11s
  def InstallStack

  end
  
  #as main ip we take the address of the first interface
  def GetIpFromId(id)
     "192.168.0.#{id+1}"
  end
 
  #get the subnet used for nodes
  def GetSubnet()
      "192.168.0.0/16"
  end  
  
  def SetIp(node)
    	i=0
	if @interfaces.size()>1
	    $stderr.puts "802.11s stack does not support multi-radio nodes. Exiting."
	    exit(1)
	    return
	end
     	@interfaces.each do |ifn|
	  self.GetGroupInterface(node, ifn).ip="192.168.#{i}.#{node.id+1}/24"
  	  self.GetGroupInterface(node, ifn).up
	  i=i+1
	end
  end
  
  #the essid is set automatically in SetMode (see ath5k.rb in orbit/patches)
  def SetEssid(node)
    
  end
  
  
  def SetMode(node)
     	@interfaces.each do |ifn|
	    if (@setradios and ifn.IsWifi())
		self.GetGroupInterface(node,ifn).mode="mesh"
		self.GetGroupInterface(node,ifn).type="a"
	    end
	    
	end
  end
  
  #no software to start (all in the kernel)
  def StartStack

  end
  
  #no software to stop
  def StopStack
  
  end

end
