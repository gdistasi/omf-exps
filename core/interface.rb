
class Address
  
  attr_accessor :ip, :netmask
  
  def initialize(ip, netmask)
    @ip=ip
    @netmask=netmask
  end
  
  
end

class Interface
  
    attr_accessor :name

    
    def GetName()
      @name
    end
    
    def initialize(name)
      @name=name
      @addresses = Array.new
    end
    
    def IsEthernet()
      return true
    end
    
    def AddAddress(address)
      @addresses << address
    end
    
end