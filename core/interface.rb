
class Address
  
  attr_accessor :ip, :netmask
  
  def initialize(ip, netmask)
    @ip=ip
    @netmask=netmask
  end
  
  def to_s
    return "#{ip}"
  end
  
end

class Interface
  
    attr_accessor :name

    def initialize()
      @addresses = Array.new
    end
    
    def GetName()
      @name
    end
    
    def SetName(name)
      @name=name
    end

    def AddAddress(address)
      @addresses << address
    end
    
    def GetAddresses()
      @addresses
    end
    
    def IsWifi
       return false
    end
    
    def IsEthernet
      return false
    end
    
end


class EthernetInterface < Interface
  
  def IsEthernet
    return true
  end
  
  
end