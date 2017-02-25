
class Orbit
class Topology
  
class Node
  
    attr_accessor :id, :x, :y, :radios, :type, :name, :attributes
  
    def initialize(id, name, type="R")
      @id=id
      @name=name
      @interfaces = Array.new
      @attributes = Array.new
      #AddInterface(Interface.new("control"))
      #AddInterface(Interface.new("data"))
      @aliases = Set.new
    end
    
    def GetName
      @name
    end
    
    def SetPos(x,y)
      @x=x
      @y=y
    end
    
    def GetAlias
      @alias
    end
    
    def SetType(type)
      @type=type
    end
        
    def AddAlias(aliase)
      @alias=aliase
    end
    
    def HasAlias(aliase)
      puts @alias
      puts aliase
	return aliase==@alias
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
      
      return adds.to_a
    end
    
    def AddInterfaces(interf)
      @interfaces=interf
    end
    
    def GetControlInterface()
      return @interfaces[0]
    end
    
    def HasAttribute(att)
      has=false
      @attributes.each do |a|
	 if (a==att) then
	   has=true
	 end
      end
      return has
    end
    
    def AddAttribute(att)
      @attributes << att
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
   
   def SetRoutingStack(rstack)
      @rstack=rstack
   end
  
   def GetRoutingStack()
    return @rstack
   end
   
end

end

end
