


 class Node
  
    attr_accessor :id, :x, :y, :radios, :type
  
    def initialize(id, type, x, y, radios)
      @x = x
      @y = y
      @numRadios = numRadios
      @type = type
      @id=id
      @addresses = Array.new
    end
    
    
    def AddAddress(ip,netmask,interface)
      @addresses << Address.new(ip,netmask,interface)
    end
    
    def AddInterfaces(interf)
      @interfaces=interf
    end
    
    def GetId()
      return id
    end
    
    def GetType()
      return type
    end
    
    def GetAddresses
      return @addresses
   end
   
   def SetRoutingStack(rstack)
      @rstack=rstack
   end
  
   def GetRoutingStack()
    return @rstack
   end
   
   
   
   
end
  
