require 'core/orbit.rb'
require 'core/apps.rb'
require 'traffic/ditg-helper.rb'
require 'traffic/flow.rb'

#Allocate a flow between each sender-receiver couple. 
#It must be created and, when the testbed is ready (after the OMF whenAllInstalled statement), started.
class SenderReceiverPattern

  def initialize(orbit, demands, protocol="UDP", duration=120, biflow=false, dirtyfix=false)
    @duration=duration
    
    @demands=Array.new
     
    @protocols=protocol.to_s.split(",")
    
    @dirtyfix=dirtyfix
    
    demands.to_s.split(",").each do |demand|
	@demands << Float(demand)
    end
    
    @receiverApps = Orbit::ApplicationContainer.new
    @itgManagers = Orbit::ApplicationContainer.new
    @daemons = Orbit::ApplicationContainer.new

    @orbit=orbit

    @biflow=biflow=="yes"
    
    @rttm=false
    
    if (@biflow)
      file=File.open("exp-var.sh","a")
      file.puts("BIFLOW=\"yes\"")
      file.close()
    end
    
    
  end
  
  def TurnRttmOn
    @rttm=true
  end

  #install ITGRecv on each receiver and ITGSend and ITGManager on each sender
  def InstallApplications

    #get the senders and receivers
    #orbit manages the topology which also specifies the sender and receiver nodes
    senders=@orbit.GetTopology().senders
    receivers=@orbit.GetTopology().receivers
    
    #helpers used to allocate ITGRecv on receiving nodes 
    itgReceiver=ITGReceiverHelper.new(@orbit)

    receiverNodes=Array.new(receivers)
    senderNodes=Array.new(senders)
    
     # if we want a flow for each direction install itgrecv also on both aggregators and senders
     if (@biflow)
      	senders.each do |n|
	  receiverNodes << n
	end
  	receivers.each do |n|
	  senderNodes << n
	end
     end
     
     
    #there is a receiver for each type of protocol so we
    #associate a signaling port to each of them
    sigChPort=9000
    @mapProtocols=Hash.new
    @protocols.each do |proto|
	@mapProtocols[proto]=sigChPort
	sigChPort=sigChPort+1
    end
    
    receiverNodes.each do |receiver|
      @protocols.each do |proto|
        itgReceiver.SetLogFile("/tmp/ditg.log-receiver-#{proto}-node-#{receiver.id}")
        itgReceiver.SetSigChannelPort(@mapProtocols[proto])
	@receiverApps.Add(itgReceiver.Install(receiver.id))
      end
  
      if (@dirtyfix)
	    @orbit.Node(receiver.id).exec("ip route add to 5.100.0.0/16 dev #{@orbit.GetControlInterface()}")
      end
    end
    
    #install the itg daemons and the itg manager
    itgSenderDaemon=ITGDaemonHelper.new(@orbit)
    itgManagerHelper=ITGManagerHelper.new(@orbit)
    

    senderNodes.each do |sender|
	@daemons.Add(itgSenderDaemon.Install(sender.id))
	itgManager=itgManagerHelper.Install(sender.id)
	@itgManagers.Add(itgManager)
	if (@dirtyfix)
	  @orbit.Node(sender.id).exec("ip route add to 5.100.0.0/16 dev #{@orbit.GetControlInterface()}")
	end
    end
    
    @senders=senderNodes
    @receivers=receiverNodes
    

  end
    
  def FindITGManager(sender)
    @itgManagers.apps.each do |app|
      if app.node==sender.id
	return app
      end
    end
    return nil
  end
  
   def FindITGRecv(receiver, proto)
    @receiverApps.apps.each do |app|
      if app.node==receiver and  app.GetSigChannelPort()==@mapProtocols[proto]
	return app
      end
    end
    return nil
  end
  
  def Start
    #start the applications
    info("Starting traffic generation.")
    
        @receiverApps.StartAll
    info("Waiting for ITGRecv instances to start...")
    wait(20)
    @daemons.StartAll
    @itgManagers.StartAll   
    
    
    
      @protocols.each do |proto| 
	i=0
	@senders.each do |sender|
	  @receivers.each do |receiver|
	    @protocols.each do |proto|
	      if (sender==receiver) then next end
	      flow=Flow.new(0, @demands[i%@demands.size], sender, receiver, FindITGRecv(receiver, proto))
	      flow.SetEnd(@duration)
	      info("Starting a flow from #{flow.sender.id} to #{flow.receiver.id}, protocol #{proto}, at #{flow.bitrate} kbps")
	      itgRecv=FindITGRecv(flow.receiver.id, proto)
	      cmd=MakeDITGCmdLine(flow, itgRecv, 500, proto, @rttm)
	      logF="/tmp/itgSenderLog-#{proto}-#{flow.sender.id}-#{flow.receiver.id}"
	      info("Command on node #{flow.sender.id}: #{cmd} ")
	      @orbit.Node(flow.sender.id).exec("#{cmd} >#{logF} 2>&1")
	    end
	
	    i=i+1

	  end
	end
     end
    
    
    
 
  end
 
end


if __FILE__ == $0

end
