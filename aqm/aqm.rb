




class AqmConfigurator
  
  
  def initialize(aqm_policy, options)
    @policy=aqm_policy
    @options=options
  end
  
  def ResetCmd(ifn)
    return "tc qdisc del dev #{ifn} root"
  end
  
  
  def GetCmd(ifn)
    
    if (@policy=="pfifo_fast") then
      cmd="tc qdisc add dev #{ifn} root pfifo_fast"      
    elsif (@policy=="fq_codel") then
      cmd="tc qdisc add dev #{ifn} root fq_codel"      
    elsif
      throw "The aqm policy #{@policy} is not supported!."
    end
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