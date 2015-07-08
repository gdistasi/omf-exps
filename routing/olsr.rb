require 'core/orbit.rb'
require 'core/routing_stack.rb'
require 'core/apps.rb'
require 'set'
require 'test/unit'

class OrbitOlsr < RoutingStack
     
  #define some properties that can be set from the command line
  def DefProperties
      super
      defProperty('olsrdebug', 0, "level of debugging output of olsr to be saved")
      defProperty('switchOff', 'no', "set to yes to ask to switch off and then on an interface after a channel change")
      defProperty('flushRoutingRules', 'no', "Delete the routing rules referring to mesh interfaces before starting Olsrd")
  end
  

  
 def InstallStack
     
    @receivers=@orbit.GetReceivers()
   
    #install Layer2.5 stack on each node
    stackApp=OlsrHelper.new(@orbit.GetInterfaces(), @orbit)
    stackApp.SetOlsrDebug(property.olsrdebug)
      
    GetNodes().each do |node|
      
      if (node.type!="R" and node.type!="A" and node.type!="G")
	next
      end
      
      #if (node.id==GetGateways()[0].id)
      # stackApp.SetGateway(true)
      #else
	  stackApp.SetGateway(false)
      #end
      stackApp.FlushRoutingRules()
      @rules.to_a.each do |rule|
	if rule.gateway==GetIpFromId(node.id)
	  stackApp.AddRoutingRule(rule.to,"255.255.255.255")
	end
      end
      @stackApps.Add(stackApp.Install(node.id))
    end
    
    
 end
  
  #get the subnet used for nodes
  def GetSubnet()
      "5.100.0.0/16"
  end 
  
  #get the node main address
  def GetIpFromId(id)
     "5.100.0.#{id+1}"
  end
 
 def StartStack
    @stackApps.StartAll
 end

 def AddRoutingRule(to, gateway)
    if (@rules==nil)
      @rules = Set.new
    end
    @rules.add(Rule.new(to,gateway))
 end
 
 def StopStack

 end
 
 class Rule
   
   attr_accessor :to, :gateway

   def initialize(to,gateway)
     @to=to
     @gateway=gateway
   end
   
 end
 
end
