require 'core/orbit.rb'
require 'utils/utils.rb'

#File which includes helpers for installing applications on nodes
#The Install functions return instances of Orbit::Application
  
#include Commands from OMF EC
include OMF::EC::Commands

#helper used to instantiate the layer2.5 stack on a node
class Layer25Helper
   
  @@defined=false
  
  def initialize(interfaces, orbit, kernelmode=false)
    @interfaces=interfaces
    @isgateway=false
    @name="layer25"
    @path="ruby /usr/local/bin/mesh.rb >>/var/log/mesh.log 2>&1"
    

    @orbit=orbit
    @kernelmode=kernelmode
    @debug=false
    @olsrdebug=0
   
    @hnas = ""

    if (@@defined==false)
      self.DefineApp
      @@defined=true
    end
    
  end

  def SetKernelMode(mode)
	@kernelmode=mode
  end
   
  def SetOlsrDebug(level)
      @olsrdebug=level
  end
  
  def SetDebug(debug)
	@debug=debug
  end
  
  def EnableAggregation(en=true)
    @aggregationEnabled=en
  end
  
  def SetAggregationDelay(delay)
    @aggregationDelay=delay
  end
  
  def SetAggregationAlgo(algo)
    @aggregationAlgo=algo
  end
  
  def SetWeigthFlowrates(w)
    @weigthFlowrates=w
  end

  def Install(node_id)

    group("node#{node_id}").addApplication('layer25application', :id => @name ) do |app|
	  app.setProperty('id', node_id)
	  
	  #if orbit sets the radio, L2R does not
	  if (@setradios==false)
	    app.setProperty('setradios', true)
	  else
	    app.setProperty('setradios', false)
	  end
	  interfaces=""
	  @interfaces.each do |int|
	      interfaces="#{interfaces}#{int.name}:#{int.type},"
	  end
	  interfaces.chomp!(",")
	  
	  app.setProperty('interfaces', interfaces)
	  
	  if (@isgateway)
	    app.setProperty('gateway',true)
	  end
	
	  if (@debug)
		app.setProperty('debug',true)
	  end	  

          if (@kernelmode)
		app.setProperty('kernelmode', true)
          end

	  if (property.switchOff.to_s=="yes")
		app.setProperty('switchOff', true)
	  end
	  
	  if (@aggregationEnabled)
		app.setProperty('aggregation', true)
		app.setProperty('aggregationDelay', @aggregationDelay)
	  end
	  
	  if (@aggregationAlgo!=nil)
		app.setProperty('aggregationAware', true)
		app.setProperty('aggregationAwareAlgorithm', @aggregationAlgo)
	  end
	  
	  if (@weigthFlowrates!=nil and @weigthFlowrates==true)
	    app.setProperty('weigthFlowrates', true)
	  end
	  
	  if (property.invalidateLinks.to_s=="yes" or property.invalidateLinks == 1 or property.invalidateLinks.to_s == "true")
		app.setProperty('invalidateLinks', true)
	  end
	  
	  if (@hnas!="")
		app.setProperty('hnas',@hnas)
	  end
	  
	  app.setProperty('olsrdebug', @olsrdebug)
	  
	  info "Adding LayerStack to node #{node_id}"
   end
            
   layer=Layer25Stack.new(node_id, @name, @orbit)
   layer.SetKernelMode(@kernelmode)
   
   return layer

  end
  
  def FlushRoutingRules()
      @hnas=""
  end
  
  def AddRoutingRule(network,netmask)
      @hnas = "#{@hnas}#{network}-#{netmask},"
  end
  
  def SetGateway(gw)
    @isgateway=gw
  end
  
  def DefineApp
    
    defProperty('invalidateLinks', '', "set to yes to enable the invalidation of links when channel are changed")
    defProperty('freezeTopology', "no", "set to yes to freeze the topology after the first channel assignment")
    
    
    defApplication('layer25application', 'layer25') do |app|
  
      app.path = @path  
      app.version(1, 1, 1)
      app.shortDescription = "Layer 2.5 Routing" 
      app.description = "Layer 2.5 routing stack." 
      
      if (@orbit.GetEnv()!="WILEE")
        if (@orbit.ECCanServeFiles())      
	  app.appPackage = "bin/layer2.5.tar.gz"
        else
	  app.appPackage = "http://#{@orbit.GetECAddress()}:8000/bin/layer2.5.tar.gz"
        end
      end

      app.defProperty('id', 'Node id', "--id", 
		    {:type => :integer, :dynamic => false})
      
      app.defProperty('setradios', 'Auto set of radios', "--setradio", 
		    {:type => :boolean, :dynamic => false})
      
      app.defProperty('interfaces', "List of mesh interfaces (name:type) separated by a colon.", "--interfaces",
                     {:type => :string, :dynamic => false})
      
      app.defProperty('gateway', "Set this option if the node acts as gateway.", "--gateway", {:type => :boolean, :dynamic => false})
      
      app.defProperty('debug', "Set this option to enable debug output.", "--debug", {:type => :boolean, :dynamic => false})
      
      app.defProperty('kernelmode', "Set this option to enable kernel mode.", "--kernelmode", {:type => :boolean, :dynamic => false})
      
      app.defProperty('olsrdebug', "Set this option as the debug level for Olsrd.", "--olsrdebug", {:type => :integer, :dynamic => false})
      
      app.defProperty('switchOff', "Set this option to force a switch off and then a switch on of the interface after a channel change.", "--switchOff", {:type => :boolean, :dynamic => false})
      
      app.defProperty('aggregation', "Set this option to enable aggregation", "--aggregation", {:type=> :boolean, :dynamic => false})
      
      app.defProperty('aggregationAware', "Set to enable aggregation aware routing (the specific algorithm has to be selected with the aggregationAwareAlgorithm option", "--aggregationAware", {:type=> :boolean, :dynamic => false})

      app.defProperty('aggregationAwareAlgorithm', "Set this option to select the aggregation aware algorithm: either AF-L2R or AA-L2R", "--aggregationAwareAlgorithm", {:type=> :string, :dynamic => false})

      app.defProperty('aggregationDelay', "Set this option to enable aggregation", "--aggregationDelay", {:type=> :integer, :dynamic => false})
      
      app.defProperty('invalidateLinks', "Set this option to ask Olsrd to invalidateLinks after channels are changed", "--invalidateLinks", {:type => :boolean, :dynamic => false})
      
      app.defProperty('weigthFlowrates', "Set this option to ask Layer25 to weigth the flowrates of links with their quality", "--weigthFlowrates", {:type => :boolean, :dynamic => false})

      app.defProperty('flushRoutingRules', "Set this option to flush the routing rules of mesh interfaces before starting Olsrd", "--flushRoutingRules", {:type => :boolean, :dynamic => false})
      app.defProperty('hnas', "comma-separated list of rules for external networks/hosts (network0-netmask0,network1-netmask1,... ", "--hnas", {:type => :string, :dynamic => false})
      
    end
    
    #kill any left instance on the nodes
    allGroups.exec("killall click >/dev/null 2>&1; killall caagent >/dev/null 2>&1; killall olsrd >/dev/null 2>&1; /bin/true")
  end
  
end


#class which represents an instance of the Layer25 stack on a node
class Layer25Stack < Orbit::Application

	def SetKernelMode(mode)
		@kernelmode=mode
	end

	def StopApplication
        	@orbit.Node(@node).exec("killall caagent >/dev/null 2>&1; killall olsrd >/dev/null 2>&1;")
		@orbit.Node(@node).exec("killall click > /dev/null 2>&1;")
		#super.StopApplication
                if (@kernelmode==true)
			@orbit.Node(@node).exec("rmmod click > /dev/null 2>&1;")
		end
	end

	

end
  

#helper used to instantiate the olsrd (unik) stack on a node
class OlsrHelper
  @@defined=false
  
  def initialize(interfaces, orbit)
    @interfaces=interfaces
    @isgateway=false
    @name="olsr"
    @path = "ruby /usr/local/bin/olsrd.rb" 
    @olsrdebug=0
    @orbit=orbit

    @hnas = ""
    
    if (@@defined==false)
      self.DefineApp
      @@defined=true
    end
    
  end
  
  def SetOlsrDebug(level)
    @olsrdebug=level
  end
  
  def Install(node_id)

    group("node#{node_id}").addApplication('olsrapplication', :id => @name ) do |app|
	  app.setProperty('id', node_id)
	  app.setProperty('setradios', false)
	  
	  inter_names=Array.new
	  @interfaces.each do |int|
	    inter_names << int.name
	  end

	  interfaces=""
	  @interfaces.each do |int|
	      interfaces="#{interfaces}#{int.name}:#{int.type},"
	  end
	  interfaces.chomp!(",")
	  
	  app.setProperty('interfaces', interfaces)
	  
	  if (@isgateway)
	    app.setProperty('gateway',true)
	  end
	  
	  app.setProperty('olsrdebug', @olsrdebug)
	  
	  if (property.profile.to_s!="")
	      app.setProperty('profile', property.profile.to_s)
	  end
	  
	   if (property.switchOff.to_s=="yes")
		app.setProperty('switchOff', true)
	  end
	  
	  if (property.invalidateLinks.to_s=="yes" or property.invalidateLinks == 1 or property.invalidateLinks.to_s == "true")
		app.setProperty('invalidateLinks', true)
	  end
	  
	  if (property.flushRoutingRules.to_s=="yes" or property.flushRoutingRules == 1 or property.flushRoutingRules.to_s == "true")
		app.setProperty('flushRoutingRules', true)
	  end
	  
	  if (@hnas!="")
		app.setProperty('hnas',@hnas)
	  end
	  
	  puts "Adding OlsrStack on node #{node_id}"
   end
            
   return Orbit::Application.new(node_id, @name)

  end
  
  def AddRoutingRule(network,netmask)
      @hnas = "#{@hnas}#{network}-#{netmask},"
  end
  
  def FlushRoutingRules()
      @hnas=""
  end
		               
  def SetGateway(gw)
    @isgateway=gw
  end
  
  def DefineApp
    defProperty('profile', 'standard', "profile to use for Olsrd: standard|fast|hysteresis; standard uses link quality; fast uses link quality but halved tc and hello intervals; hysteresis uses the olsrdv1 protocol.")
    defProperty('invalidateLinks', '', "set to yes to enable the invalidation of links when channel are changed")
    
    defApplication('olsrapplication', 'olsr') do |app|
  
      app.path = "ruby /usr/local/bin/olsrd.rb >>/var/log/mesh.log 2>&1"
      app.version(1, 1, 1)
      app.shortDescription = "Olsr Routing" 
      app.description = "Olsr routing stack."
      
      if (@orbit.GetEnv()!="WILEE")
      if (@orbit.ECCanServeFiles())      
	app.appPackage = "bin/layer2.5.tar.gz"
      else
	app.appPackage = "http://#{@orbit.GetECAddress()}:8000/bin/layer2.5.tar.gz"
      end
      end

      app.defProperty('id', 'Node id', "--id", 
		    {:type => :integer, :dynamic => false})
      app.defProperty('setradios', 'Auto set of radios', "--setradios", 
		    {:type => :boolean, :dynamic => false})
      app.defProperty('interfaces', "List of mesh interfaces separated by a colon.", "--interfaces",
                     {:type => :string, :dynamic => false})
      app.defProperty('gateway', "Set this option if the node acts as gateway.", "--gateway", {:type => :boolean, :dynamic => false})
      app.defProperty('olsrdebug', "Set this option as the debug level for Olsrd.", "--olsrdebug", {:type => :integer, :dynamic => false})
      app.defProperty('profile', "Profile to use (i.e. settings) for Olsrd.", "--profile", {:type => :string, :dynamic => false})
      app.defProperty('switchOff', "Set this option to force a switch off and then a switch on of the interface after a channel change.", "--switchOff", {:type => :boolean, :dynamic => false})

      app.defProperty('invalidateLinks', "Set this option to ask Olsrd to invalidateLinks after channels are changed", "--invalidateLinks", {:type => :boolean, :dynamic => false})
      app.defProperty('flushRoutingRules', "Set this option to flush the routing rules of mesh interfaces before starting Olsrd", "--flushRoutingRules", {:type => :boolean, :dynamic => false})
      app.defProperty('hnas', "comma-separated list of rules for external networks/hosts (network0-netmask0,network1-netmask1,... ", "--hnas", {:type => :string, :dynamic => false})

      allGroups.exec("killall caagent >/dev/null 2>&1; killall olsrd >/dev/null 2>&1; /bin/true")

    end
  end
    
end


class BatmanAdvHelper
   
  @@defined=false
  
  def initialize(orbit)
    @name="batmanAdv"
    @depmod="/sbin/depmod"

    
    if (@@defined==false)
      self.DefineApp
      @@defined=true
    end
    
    @orbit=orbit
   
  end

  def Install(node_id)

    group("node#{node_id}").addApplication(@name, :id => @name ) do |app|
	  info "Adding BatmanAdvanced stack to node #{node_id}"
    end
    
    sleep(1)

            
   return Orbit::Application.new(node_id, @name)

  end
  
  def DefineApp
   
    defApplication(@name, @name) do |app|
  
      app.version(1, 1, 1)
      app.shortDescription = "Batman Advanced Routing" 
      app.description = "Batman Advanced Routing"
      
      if (property.env.to_s=="ORBIT")
	envStr="Orbit"
      elsif (property.env.to_s=="MYXEN")
        envStr="Xen"
      else
	$stderr.puts("The current environment is not supported by the Batman-adv helper.")  
	exit(1)
      end
      
      if (@orbit.GetEnv()!="WILEE")
      if (@orbit.ECCanServeFiles())      
	app.appPackage = "bin/batman-adv-#{envStr}.tar.gz"
      else
	app.appPackage = "http://#{@orbit.GetECAddress()}:8000/bin/batman-adv-#{envStr}.tar.gz"
      end
      end
      
    end
    
  end
  
end


#Program that is located with a Batman node and wait for connections in order to give the topology
#that it gets from the local batman daemon
class BatmanAdvConnectorHelper
   
  @@defined=false
  
  def initialize(orbit)
    @name="batmanAdvConnector"
    
    if (@@defined==false)
      self.DefineApp
      @@defined=true
    end
    
    @orbit=orbit
   
  end

  def Install(node_id)

    group("node#{node_id}").addApplication(@name, :id => @name ) do |app|
	  info "Adding BatmanAdvancedConnector to node #{node_id}"
    end
    
   return Orbit::Application.new(node_id, @name)

  end
  
  def DefineApp
   
    defApplication(@name, @name) do |app|
      app.path = "ruby /usr/local/bin/batmanConnector.rb >>/var/log/mesh.log 2>&1"

      app.version(1, 1, 1)
      app.shortDescription = "Batman Advanced Connector" 
      app.description = "Batman Advanced Connector"
      
      if (@orbit.GetEnv()!="WILEE")
        app.appPackage = "batman-adv-connector.tar.gz"
      end
 
    end
    
  end
  
end
