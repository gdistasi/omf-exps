require 'core/orbit.rb'
require 'core/apps.rb'
require 'traffic/ditg-helper.rb'

#Allocate a number of flows. It start with one flow, and add other flows, one at a time, every duration/numFlows time interval.
#It must be created and, when the testbed is ready (after the OMF whenAllInstalled statement), started.
class FlowsPattern < IncreaseNumFlowsPattern

  #num changes represents the number of times the load changes; duration is the duration of the experiment
  def initialize(duration=120, orbit)
    @duration=duration
   
    @receiverApps = Orbit::ApplicationContainer.new
    @itgManagers = Orbit::ApplicationContainer.new
    @daemons = Orbit::ApplicationContainer.new

    @orbit=orbit

    InstallApplications()
  end

  #install ITGRecv on each receiver and ITGSend and ITGManager on each sender
  def InstallApplications

    #get the senders and receivers
    #orbit manages the topology which also specifies the sender and receiver nodes
    senders=@orbit.GetSenders()
    receivers=@orbit.GetReceivers()
    
    #helpers used to allocate ITGRecv on receiving nodes 
    itgReceiver=ITGReceiverHelper.new()

    receivers.each do |receiver|
      itgReceiver.SetLogFile("/tmp/logfile_rec_#{receiver.id}")
      @receiverApps.Add(itgReceiver.Install(receiver.id))
    end
    
    #install the itg daemons and the itg manager
    itgDaemonHelper=ITGDaemonHelper.new
    itgManagerHelper=ITGManagerHelper.new(@orbit)
     	
    senders.each do |sender|
	@daemons.Add(itgSenderDaemon.Install(sender.id))
	itgManager=itgManagerHelper.Install(sender.id)
	itgManager.SetProtocol(property.protocol.to_s)
	@itgManagers.Add(itgManager)
    end
    
    senders.each do |sender|
      receivers.each do |receiver|
        FindITGManager(sender).ScheduleFlow(Flow.new(i*interval, bitrate, sender, receiver, FindITGRecv(receiver)))
      end
    end


end


if __FILE__ == $0

end
