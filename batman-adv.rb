require './orbit.rb'
require './apps.rb'


class OrbitBatmanAdv < Orbit 

  def initialize()
    super
    @meshifn="bat0"
  end
  
  #define some properties that can be set from the command line
  def DefProperties
      super
      defProperty('switchOff', 'no', "set to yes to ask to switch off and then on an interface after a channel change")
  end
  
 def InstallStack
    @modprobe="/sbin/modprobe"
 
    batmanAdvHelper=BatmanAdvHelper.new(self)
    
    @nodes.each do |node|
	batmanAdvHelper.Install(node.id)
    end
    
    #install the BatmanAdvConnector (to give the topology)
	batmanConnectorHelper=BatmanAdvConnectorHelper.new(self)
	@batmanAdvConnector=batmanConnectorHelper.Install(@receivers[0].id)
	
	
     
 
 end
 
  def SetIp(node)
	@interfaces.each do |ifn|
	  self.GetGroupInterface(node, ifn).ip="1.1.1.1"
	  self.GetGroupInterface(node, ifn).up
	end
  end
    
  def GetIpFromId(id)
     "192.168.3.#{id+1}"
  end
 
  #get the subnet used for nodes
  def GetSubnet()
      "192.168.3.0/24"
  end  

 def StartStack
    @nodes.each do |node|
      	  #load Batman-adv module
          Node(node.id).exec("#{@depmod} -a")
	  Node(node.id).exec("#{@modprobe} batman_adv")
	  sleep(1)
	   
	  i=0
	  @interfaces.each do |ifn|	  
		  Node(node.id).exec("echo #{@meshifn} >  /sys/class/net/meshbr#{i}/batman_adv/mesh_iface")
		  i=i+1
	  end
     end
     
   

     
     @batmanAdvConnector.StartApplication
     
 end
 
  #setting for the mesh interface 
  def SetMeshInterface()
 
     @nodes.each do |node|
      Node(node.id).exec("/sbin/ifconfig #{@meshifn} #{GetIpFromId(node.id)}")
      Node(node.id).exec("/sbin/ifconfig #{@meshifn} mtu 1500")
     end
  end
     
  #set the mtu of the interfaces - do nothing if not overriden
  def SetMtu(node)
	@interfaces.each do |ifn|
	  self.GetGroupInterface(node, ifn).mtu="1528"
	end
  end
 
 def StopStack
    @nodes.each do |node|
		i=0
	      	@interfaces.each do |ifn|
		    
		    Node(node.id).exec("echo none > /sys/class/net/meshbr#{i}/batman_adv/mesh_iface")
		    Node(node.id).exec("brctl delbr meshbr#{i}")
		    
		    i=i+1
		end
		
		Node(node.id).exec("#{@modprobe} -r batman-adv")

    end
 end

  def GetStackStats(filename="stats-batman-adv.txt")
	nodes=GetNodes()
	click_port=7777
	stat=File.open(filename,"w")
	
	@nodes.each do |node|
	  
	  stat.puts("Node #{node.id}")
	      
	end
	
  end
  
  def SetUpNodes
  
     #create a bridge for each interface which will serve as filtering point (to drop packets from non-neighbors)
     @nodes.each do |node|
        i=0
	@interfaces.each do |ifn|
	    Node(node.id).exec("brctl addbr meshbr#{i}")
	    Node(node.id).exec("brctl stp meshbr#{i} off")
	    i=i+1
	end
     end
     
     @nodes.each do |node|
      	  #load Batman-adv module
	  Node(node.id).exec("#{@modprobe} batman_adv")
	  sleep(1)
	   
	  i=0
	  @interfaces.each do |ifn|	  
		  Node(node.id).exec("echo #{@meshifn} >  /sys/class/net/meshbr#{i}/batman_adv/mesh_iface")
		  i=i+1
	  end
     end
     
     #setting up the wireless interfaces as usual
     super
     
     #adding the wireless interfaces to the bridges
     @nodes.each do |node|
	i=0
	@interfaces.each do |ifn|
	    Node(node.id).exec("brctl addif meshbr#{i} #{ifn.name}")
	    Node(node.id).exec("ifconfig meshbr#{i} up")
	    i=i+1
	end
     end
  
  end
  
  
  def InstallTcpdump
     
     super
     tcpdumpHelper=TcpdumpHelper.new
     @nodes.each do |node|   
	@tcpdumpApps.Add(tcpdumpHelper.Install(node.id, "#{@meshifn}"))
     end 
     
  end
 
end
