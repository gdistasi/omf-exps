


class AqmConfigurator
  
  
  def initialize(aqm_policy, options)
    @policy=aqm_policy
    @options=options
  end
  
  def ResetCmd(ifn)
    return "tc qdisc del dev #{ifn} root"
  end
  
  
  def GetCmd(ifn)
      cmd="tc qdisc add dev #{ifn} root #{@policy} #{@options}"      
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