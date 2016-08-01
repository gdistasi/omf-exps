require 'core/orbit.rb'
require 'core/routing_stack.rb'
require 'core/apps.rb'
require 'set'
require 'test/unit'

class OrbitOlsr < RoutingStack
     
  def initialize(prefix)
    super()
    @prefix=prefix
   end
  
  #define some properties that can be set from the command line
  def DefProperties
      super
      puts("CALLING DEF PROPERTIES!")
      defProperty('olsrdebug', 0, "level of debugging output of olsr to be saved")
      defProperty('switchOff', 'no', "set to yes to ask to switch off and then on an interface after a channel change")
      defProperty('flushRoutingRules', 'no', "Delete the routing rules referring to mesh interfaces before starting Olsrd")
  end
  

  
 def InstallStack
     
    #@receivers=@orbit.GetReceivers()

     @orbit.GetNodes().each do |node|  
      node.GetInterfaces().each do |ifn| 
	if (ifn.IsWifi()) then
	      address=Address.new("#{@prefix}.#{ifn.GetChannel()}.#{node.GetId()+1}",24)
	      ifn.AddAddress(address)
	      @orbit.AssignAddress(node, ifn, address)
	end
      
	if (ifn.IsWifi()) then
	   if (ifn.GetMode()=="station") then
	      #@orbit.RunOnNode(node, "ip address del default; ip address add default #{@orbit.GetRealName(node, ifn)}")
	   end
	end
	
      end
     end
    
    GetNodes().each do |node|
      
      if (node.type!="R" and node.type!="A" and node.type!="G")
	next
      end
      
         
    stackApp=OlsrHelper.new(node.GetInterfaces(), @orbit)
    stackApp.SetOlsrDebug(property.olsrdebug)
      
     @orbit.AddLogFile(node, "/tmp/olsrd.log")
     @orbit.AddLogFile(node,"/tmp/olsrd-2.conf")
     
      
      #if (node.id==GetGateways()[0].id)
      # stackApp.SetGateway(true)
      #else
	  stackApp.SetGateway(false)
      #end
      stackApp.FlushRoutingRules()
      #@rules.to_a.each do |rule|
	#if rule.gateway==GetIpFromId(node.id)
	#  stackApp.AddRoutingRule(rule.to,"255.255.255.255")
	#end
      #end
      @stackApps.Add(stackApp.Install(node))
    end
    
    
    
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
