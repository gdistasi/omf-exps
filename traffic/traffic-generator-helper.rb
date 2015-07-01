
#port used by default by receiver instances (e.g. iperf in server mode)
REC_DEF_PORT=31000

class TrafficGeneratorHelper
  
  def initialize(protocol, name, bitrate, duration=60)
    @protocol=protocol  #either TCP or UDP
    @name=name
    @startDelay=0
    @bitrate=bitrate
    @receiverPort=REC_DEF_PORT
    @duration=duration
  end
  
  def SetSender(sender)
    @sender=sender
  end
  
  def SetReceiver(receiver)
    @receiver=receiver
  end
  
  def SetReceiverPort(port)
    @receiverPort=port
  end
  
  def SetDuration(duration)
    @duration=duration
  end
  
  #seconds to wait before starting the generation of traffic
  def StartDelay(delay)
    @startDelay=delay
  end
   
end

class TrafficSinkHelper
  
  def initialize(protocol, name, port=REC_DEF_PORT, duration=60)
    @protocol=protocol
    @port=port
    @name=name
    @windowSize=64000 #taken from OMF example
    @duration=duration
  end
  
  
  def SetDuration(duration)
    @duration=duration
  end
  
  def SetReceiverPort(port)
    @port=port
  end
  
end
