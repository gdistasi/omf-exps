
class IperfSenderHelper < TrafficGeneratorHelper
  
    def initialize(protocol, bitrate)
      super(protocol, "iperfsender", bitrate)
      @iperfInterval=5
    end
  
  
    def Install(node_id)
            
      if (@receiver == nil)
	$stderr.puts("Receiver not defined for IperfSender.")
	exit 1
      end
      
      appName="#{@name}-#{node_id}-#{@receiver}"
      
      group("node#{node_id}").addApplication("test:app:iperf", :id => appName ) do |app|
	app.setProperty("time", @duration)
	if @protocol=="UDP"
	  app.setProperty("udp", true)
	end
	app.setProperty("client", @receiver)
	app.setProperty("port", @receiverPort)
	app.setProperty("bandwidth", @bitrate)
	app.setProperty("interval", @iperfInterval)
      end
      
      return Orbit::Application.new(node_id, appName)
    end
    
    #iperf interval (-i option)
    def SetInterval(interval)
      @iperfInterval=interval
    end
    
end

class IperfSinkHelper < TrafficSinkHelper
  
  def initialize(protocol)
      super(protocol, "iperfreceiver")
      @iperfInterval=5
  end
  
  #iperf interval (-i option)
  def SetInterval(interval)
      @iperfInterval=interval
  end
  
  def Install(node_id)
       
      #used port name to distinguish among different (iperf) receivers on the same node
      appName="#{@name}-#{@port}"
      
      group("node#{node_id}").addApplication("test:app:iperf", :id => appName ) do |app|
	app.setProperty("time", @duration)
	if @protocol=="UDP"
	  app.setProperty("use_udp", true)
	end
	app.setProperty("server", true)
	app.setProperty("interval", @iperfInterval)
      end
      
      return Orbit::Application.new(node_id, appName)
  end
    
end
   



