
class Orbit
class Topology
  
class Node
  
    attr_accessor :id, :x, :y, :radios, :type, :name
  
    def initialize(id, name, type="R")
      @id=id
      @name=name
      @interfaces = Array.new
      AddInterface(Interface.new("control"))
      AddInterface(Interface.new("data"))
    end
    
    def SetPos(x,y)
      @x=x
      @y=y
    end
    
    #def initialize(id, type, x, y, radios=0)
    #  @x = x
    #  @y = y
    #  @numRadios = numRadios
    #  @type = type
    #  @id=id
    #  @addresses = Array.new

    #end
        
    def AddAddress(address, ifn)
      ifn.AddAddress(address)
    end
    
    def AddInterfaces(interf)
      @interfaces=interf
    end
    
    def GetControlInterface()
      return @interfaces[0]
    end
    
    def GetDataInterface()
      return @interfaces[1]
    end
    
    def AddInterface(int)
      @interfaces << int
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

end

end
