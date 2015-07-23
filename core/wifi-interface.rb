require "core/interface.rb"


class WifiInterface < Interface
  
  #master, station or adhoc
  def SetMode(mode)
    @mode=mode
  end
  
  def IsWifi()
    return true
  end

  def SetChannel(channel)
    @channel=0
  end
  
  def GetMode()
    @mode
  end
  
  
  def GetChannel()
    return @channel
  end
  

end