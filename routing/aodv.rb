require './orbit.rb'
require './apps.rb'
require './aodv-helper.rb'


class OrbitAodv < Orbit 
  
  #define some properties that can be set from the command line
  def DefProperties
 	super
	#defProperty('logRtTable', '5', "Default Log routing table to %s every N secs")  
  end
  

 def InstallStack
 
    #install the application on each node
    stackApp=AodvHelper.new(@interfaces, self)
    @nodes.each do |node|
       @stackApps.Add(stackApp.Install(node.id))
    end
    
   end
    
 def GetIpFromId(id)
     "192.168.0.#{id+1}"
 end
 
 def SetDebug(debug)
   
 end
 
  #get the subnet used for nodes
  def GetSubnet()
      "192.168.0.0/16"
  end  

 def StartStack
       GetNodes().each do |node|
       if (property.env.to_s=="ORBIT")
	 
            Node(node.id).exec("killall aodvd 2>/dev/null; sleep 1; /sbin/modprobe -r kaodv 2>/dev/null ; sleep 1; /sbin/depmod; sleep 1; /sbin/modprobe kaodv ifname=\"wlan0\"")
	    
            #@orbit.Node(node.id).exec("ifconfig wlan1 down")
       elsif (property.env.to_s=="MYXEN")
	       Node(node.id).exec("depmod ; modprobe kaodv ifname=\"eth0\" ")
               Node(node.id).exec("insmod /lib/modules/2.6.39/aodv/kaodv.ko")
               Node(node.id).exec("ifconfig eth2 down")
       else
            $stderr.puts("Environment not supported by AODV!")
            exit(1)
       end
       Node(node.id).exec("tc qdisc del dev eth0 root")
#      @orbit.Node(node.id).exec("date > /tmp/started")
    end
    wait(15)
    
    @stackApps.StartAll
 end
 
       
 #def SetIp(node, ifn)
 def SetIp(node)
    i=0
    
    @interfaces.each do |ifn|
        self.GetGroupInterface(node, ifn).ip="192.168.#{i}.#{node.id+1}"
	i=i+1
    end
 
 end

 def StopStack
    @stackApps.StopAll
    
    GetNodes().each do |node|
      Node(node.id).exec("killall aodvd; sleep 1; /sbin/modprobe -r kaodv")
    end
    
 end
 
end
