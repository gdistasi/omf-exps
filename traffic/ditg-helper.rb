require 'traffic/traffic-generator-helper.rb'

class ITGDaemonHelper

    @@defined=false
  
    def initialize(orbit, logfile="")
      @logfile=logfile
      @name="itgdaemon"
      @orbit=orbit
      
      if (@@defined == false)
	DefineApp()
	@@defined=true
      end
      
    end
    
    def SetLogFile(logfile)
      @logfile=logfile
    end
  
    def Install(node_id)      
      appName = "#{@name}"
      group("node#{node_id}").addApplication("itgdaemon", :id => appName) do |app|
	if (@logfile!="")
	  app.setProperty("logfile",@logfile)
	end
      end
      return Orbit::Application.new(node_id, appName)
    end
    
    def DefineApp
       defApplication('itgdaemon','itg') do |app|
	    app.path = "/usr/bin/ITGSend -Q >/tmp/itgsend.log 2>&1"
	    
	    if (@orbit.GetEnv()!="WILEE")
	      if (@orbit.ECCanServeFiles())      
	        app.appPackage = "bin/ditg.tar.gz"
	      else 
	        app.appPackage = "http://#{@orbit.GetECAddress()}:8000/bin/ditg.tar.gz"
	      end
	    end
    	    app.version(1,1,1)
	    app.shortDescription = "ITGSender in daemon mode" 
	    app.description = "ITGSender in daemon mode"    
	    app.defProperty('logfile', "Logfile", "-l",
		      {:type => :string, :dynamic => false})
	    #app.bindProperty('l', 'logfile')
	end
	
	#kill any ITGSend daemon instance on the nodes
	allGroups.exec("killall ITGSend 2>/dev/null || /bin/true")
	
    end
  
end

#class which is able to handle an ITGManager instance.
#It can 1) start the application; 2) send messages to the application in order to start new flows.
class ITGManager < Orbit::Application
  
  def initialize(node, name, orbit=nil)
    super(node,name,orbit)
    @schedFlows=Array.new
  end
  
  def SetProtocol(protocol)
	@protocol=protocol
  end

  def ScheduleFlow(flow)
    @schedFlows << flow
  end

  def StartApplication
    super
    wait(3)
    @schedFlows.each do |flow|
      StartFlow(flow, flow.itgRecv, flow.start)
    end
  end

  def StartFlow(flow, itgRecv, delay=0)

    if (@protocol==nil)
	@protocol="TCP"
    end

    pktSize=500
    pktPerSec=((Float(flow.bitrate)*1024)/(pktSize*8)).to_i
    
    puts "pktPerSec #{pktPerSec} - rate #{flow.bitrate}"
    
    port=itgRecv.GetFreePort()
    cmd="-a #{flow.receiver.GetAddresses()[0].ip}  -rp #{port} -Sdp #{itgRecv.GetSigChannelPort()} -T #{@protocol} -t #{(flow.stop-flow.start)*1000} -C #{pktPerSec} -c #{pktSize} -j 0"
      
    if (delay!=0)
      cmd="#{cmd} -d #{delay}"
    end
    
    puts "Starting flow: #{cmd}"
  
    SendMessage(cmd)
  end
  
end

#class that represents an ITGRecv instance 
class ITGRecv < Orbit::Application
  def initialize(node, name, orbit=nil)
    super(node,name, orbit)
    @startPort=REC_DEF_PORT
  end
  
  def SetSigChannelPort(port)
    @sigChannelPort=port
  end
  
  def GetSigChannelPort()
    return @sigChannelPort
  end
  
  def GetFreePort()
    port=@startPort
    @startPort=@startPort+1
    return port
  end
  
  
end


class ITGReceiverHelper < TrafficSinkHelper
  
    @@defined=false
  
    def initialize(orbit, logfile="")
      super("noprotocol", "itgreceiver")
      @logfile=logfile
      @orbit=orbit
      
      if (@@defined == false)
	DefineApp()
	@@defined=true
      end
      
      @sigChannelPort=9000
      
    end
 
    def SetSigChannelPort(port)
      @sigChannelPort=port
    end
    
    def Install(node_id)
      appName = "#{@name}-#{@sigChannelPort}"
      
      group("node#{node_id}").addApplication("itgreceiver", :id => appName) do |app|
	if (@logfile!="")
	  app.setProperty("logfile",@logfile)
	  if (@sigChannelPort!=nil)
	    app.setProperty("sigChannelPort",@sigChannelPort)
	  end
	end
      end
      
      rec=ITGRecv.new(node_id, appName)
      if (@sigChannelPort!=nil)
	rec.SetSigChannelPort(@sigChannelPort)
      end
      
      return rec
      
    end
    
    def SetLogFile(logfile)
      @logfile=logfile
    end
    
    def DefineApp
       defApplication('itgreceiver','itg') do |app|
	    app.path = "/usr/bin/ITGRecv"
	    if (@orbit.GetEnv()!="WILEE")
	    if (@orbit.ECCanServeFiles())      
	      app.appPackage = "bin/ditg.tar.gz"
	    else
	      app.appPackage = "http://#{@orbit.GetECAddress()}:8000/bin/ditg.tar.gz"
	    end
	    end
	    app.version(1,1,1)
	    app.shortDescription = "ITGReceiver" 
	    app.description = "D-ITG receiver component" 
	    
	    app.defProperty('sigChannelPort', "Port where ITGRecv listens for signaling.", "-Sp", 
	                    {:type => :integer, :dynamic => false})
	    app.defProperty('logfile', "Logfile", '-l',
		      {:type => :string, :dynamic => false})
	    #app.bindProperty('l', 'logfile')
	end
	
	#kill previous instances of ITGRecv
	allGroups.exec("killall ITGRecv 2>/dev/null || /bin/true")
	
	#delete old logfiles
	allGroups.exec("rm -f /tmp/itgrec-log")

	
    end
    
    
end

def MakeDITGCmdLine(flow, itgRecv, pktSize, protocol=nil)
    if (protocol==nil)
	protocol="TCP"
    end
    pktPerSec=((flow.bitrate*1024)/(pktSize*8)).to_i
    port=itgRecv.GetFreePort()
  
    return "ITGSend -a #{flow.receiver.GetAddresses()[0].ip}  -rp #{port} -Sdp #{itgRecv.GetSigChannelPort()} -T #{protocol} -t #{(flow.stop-flow.start)*1000} -d #{flow.start} -C #{pktPerSec} -c #{pktSize} -j 0"
end  
  

class ITGSender < ITGManager

  def initialize()
    @flows=""
  end

  def AddFlow(flow, itgRecv)

    if (@protocol==nil)
	@protocol="TCP"
    end

    pktSize=500
    pktPerSec=((flow.bitrate*1024)/(pktSize*8)).to_i
    port=itgRecv.GetFreePort()
    
    @flows="#{@flows}\n-a #{flow.receiver.GetAddressess()[0].ip}  -rp #{port} -T #{@protocol} -t #{(flow.stop-flow.start)*1000} -d #{flow.start} -C #{pktPerSec} -c #{pktSize} -j 0"
  end

  def Start
    #Launch the ITGDaemon application
    super.Start

    #Make the ITGDaemon start the flows
    SendMessage(@flows)
  end

end





class ITGManagerHelper

    @@defined=false
  
    def initialize(orbit)
      @logfile="/tmp/itgmanager.log"
      @name="itgmanager"
      @orbit=orbit
      
      #kill previous ITGManager istances
      #
      if (@@defined == false)
	DefineApp()
	@@defined=true
      end
      
    end
    
    def SetLogFile(logfile)
      @logfile=logfile
    end
  
    def Install(node_id)
      
      appName = "#{@name}"
      
      group("node#{node_id}").addApplication("itgmanager", :id => appName)
      
      return ITGManager.new(node_id, appName, @orbit)
    end
    
    def DefineApp
	defApplication('itgmanager', 'itgman') do |app|
	    app.path = "/usr/bin/ITGManager 127.0.0.1 > #{@logfile} 2>&1 "
	    app.version(1,1,1)
	    app.shortDescription = "ITGManager"
	    app.description = "Manager to be used to control an ITGSend instance in daemon mode"
	end
	
	#kill any ITGManager instance on the nodes
	allGroups.exec("killall ITGManager 2>/dev/null || /bin/true")

	
    end
  
end

class ITGSenderHelper < ITGManagerHelper

   def Install(node_id)
      
      appName = "#{@name}"
      
      group("node#{node_id}").addApplication("itgmanager", :id => appName)
      
      return ITGSender.new(node_id, appName, @orbit)
   end
 
end
