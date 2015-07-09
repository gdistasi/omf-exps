require 'core/orbit.rb'
require 'core/apps.rb'
require 'traffic/ditg-helper.rb'

#Allocate a number of flows. It starts with one flow, and add other flows, one at a time, every duration/numFlows time interval.
#It must be created and, when the testbed is ready (after the OMF whenAllInstalled statement), started.
class IncreaseNumFlowsPattern

  #num changes represents the number of times the load changes; duration is the duration of the experiment
  def initialize(orbit, demands, protocol="UDP", numFlows=1, duration=120, biflow=false)
    @duration=duration
    @numFlows=numFlows
    
    @demands=Array.new
     
    @protocol=protocol
    
    demands.to_s.split(",").each do |demand|
	@demands << Float(demand)
    end
    
    @receiverApps = Orbit::ApplicationContainer.new
    @itgManagers = Orbit::ApplicationContainer.new
    @daemons = Orbit::ApplicationContainer.new

    @orbit=orbit

    @biflow=biflow
    
    if (@biflow)
      file=File.open("exp-var.sh","a")
      file.puts("BIFLOW=\"yes\"")
      file.close()
    end
    
    
  end

  #install ITGRecv on each receiver and ITGSend and ITGManager on each sender
  def InstallApplications

    #get the senders and receivers
    #orbit manages the topology which also specifies the sender and receiver nodes
    senders=@orbit.GetSenders()
    receivers=@orbit.GetReceivers()
    
    #helpers used to allocate ITGRecv on receiving nodes 
    itgReceiver=ITGReceiverHelper.new()

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
    
    receiverNodes.each do |receiver|
      itgReceiver.SetLogFile("/tmp/logfile_rec_#{receiver.id}")
      @receiverApps.Add(itgReceiver.Install(receiver.id))
    end
    
    #install the itg daemons and the itg manager
    itgSenderDaemon=ITGDaemonHelper.new
    itgManagerHelper=ITGManagerHelper.new(@orbit)
    
    senderNodes.each do |sender|
	@daemons.Add(itgSenderDaemon.Install(sender.id))
	itgManager=itgManagerHelper.Install(sender.id)
	itgManager.SetProtocol(@protocol)
	@itgManagers.Add(itgManager)
    end
    
    i=0
    interval=@duration/@numFlows
    senders.each do |sender|
      receivers.each do |receiver|
	flow=Flow.new(i*interval, @demands[i], sender.id, receiver.id, FindITGRecv(receiver))
	flow.SetEnd(@duration)
        FindITGManager(sender).ScheduleFlow(flow)
        
	if (@biflow)
	  flow=Flow.new(i*interval, @demands[i], receiver.id, sender.id, FindITGRecv(sender))
	  flow.SetEnd(@duration)
	  FindITGManager(receiver).ScheduleFlow(flow)
	end
	
	i=i+1
        if (i==@numFLows)
          break
        end
      end
      if (i==@numFlows)
        break
      end
    end
  end

  def FindITGManager(sender)
    @itgManagers.apps.each do |app|
      if app.node==sender.id
	return app
      end
    end
    return nil
  end
  
  def FindITGRecv(receiver)
    @receiverApps.apps.each do |app|
      if app.node==receiver.id
	return app
      end
    end
    return nil
  end
  
  def Start
    #start the applications
    info("Starting traffic generation.")
    @receiverApps.StartAll
    @daemons.StartAll
    @itgManagers.StartAll    
  end
 
end


if __FILE__ == $0

end
