require "core/interface.rb"


class WifiInterface < Interface

  def initialize(name, mode)
    @name=name
    @mode=mode #master, station or adhoc
    @channel=-1
  end
  
  def IsWifi()
    return true
  end

  def SetChannel(channel)
    @channel=0
  end
  
  def GetChannel()
    return @channel
  end
  

end