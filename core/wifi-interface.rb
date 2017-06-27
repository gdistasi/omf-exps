require "core/interface.rb"


class WifiInterface < Interface
  
  #master, station or adhoc
  def SetMode(mode)
    @mode=mode
    @essid="meshnet"
  end
  
  def IsWifi()
    return true
  end

  def SetChannel(channel)
    @channel=channel
  end
  
  def SetStandard(std)
     @standard=std 
  end
  
  def GetMode()
    @mode
  end
  
  def GetStandard()
     return @standard 
  end
  
  def SetEssid(essid)
    @essid = essid
  end
  
  def GetChannel()
    return Integer(@channel)
  end
  
  def SetRate(rate)
    @rate=rate
  end
  
  def GetRate()
    return @rate
  end
  
  def GetEssid()
    return @essid
  end
  

end
