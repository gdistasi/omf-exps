
class Orbit
class Topology
  
class Node
  
    attr_accessor :id, :x, :y, :radios, :type, :name
  
    def initialize(id, name, type="R")
      @id=id
      @name=name
      @interfaces = Array.new
      #AddInterface(Interface.new("control"))
      #AddInterface(Interface.new("data"))
    end
    
    def SetPos(x,y)
      @x=x
      @y=y
    end
    
    def SetType(type)
      @type=type
    end
        
    def AddAddress(address, ifn)
      ifn.AddAddress(address)
    end
    
    def GetAddresses()
      adds=Set.new

      @interfaces.each do |ifn|
	ifn.GetAddresses().each do |add|
	  adds.add(add)
	end
      end
      
      @adds
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
    
    def GetInterfaces
       @interfaces
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
