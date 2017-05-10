


class AqmConfigurator
  
  
  def initialize(aqm_policy, options)
    @policy=aqm_policy
    @options=options
  end
  
  def ResetCmd(ifn)
    return "tc qdisc del dev #{ifn} root"
  end
  
  
  def GetCmd(ifn, parent=nil)
 
      if parent == nil then
	
	if @policy == "FQ_MAC" then
  	  cmd="tc qdisc replace dev #{ifn} root noqueue"      
	else
	  cmd="tc qdisc replace dev #{ifn} root #{@policy} #{@options}"      
	end
      else
	if @policy == "FQ_MAC" then
  	  cmd="tc qdisc replace dev #{ifn} parent #{parent} noqueue"      
	else
	  cmd="tc qdisc add dev #{ifn} parent #{parent} #{@policy} #{@options}"
	end
      end
        
    return cmd
  end
  
end


class InterfaceConfigurator
  
  
  def GetCmdFeatureOn(feature, interface)
    return "ethtool -K #{interface} #{feature} on"
  end
  
  def GetCmdFeatureOff(feature, interface)
    return "ethtool -K #{interface} #{feature} off"
  end
  
  
end
