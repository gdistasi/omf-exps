  
class Flow
       
      attr_accessor :bitrate, :start, :stop, :sender, :receiver, :itgRecv
    
       def initialize(start, bitrate, sender, receiver, itgRecv=nil)
	  @start=start
	  @bitrate=bitrate
	  @sender=sender
	  @receiver=receiver
          @itgRecv=itgRecv
       end
       
       def SetSender(sender)
	 @sender=sender
       end
       
       def SetReceiver(receiver)
	 @receiver=receiver
       end
       
       def GetBitrateMbits()
	  return @bitrate/1024
       end

       def SetEnd(endtime)
	  @stop=endtime
       end
       
end
       
  
#class that stores an aggregate of flows
class AggregatorFlows
	
       def initialize()
	  @flows=Array.new
	  @allSeenFlows=Array.new
	  @totBitrate=0
	      
	  #used by NextFlow
	  @nextFlow=0
         
       end
       
       def Bitrate()
	  return @totBitrate
       end
       
       
       def PushFlows(flows)
	 #flows=aggr.GetFlows()
	 flows.each do |flow|
	   Push(flow)
	 end
       end
       
       #sort the flows in ascending order of starting time
       def Sort()
	 @flows.sort!{|x,y| x.start<=>y.start}
       end
       
       def Push(flow)
          @flows << flow
	  @allSeenFlows << flow
	  @totBitrate = @totBitrate + flow.bitrate
	  return flow
       end
       
       def Pop()
	  flow=@flows.pop
	  @totBitrate = @totBitrate - flow.bitrate
	  return flow
       end
       
       def size()
	 return @flows.size
       end
       
       def GetFlows()
	 return @allSeenFlows
       end

	#set the first as the flow to be returned by NextFlow
	def Rewind()
		@nextFlow=0
	end
       
        #return the next flow to be started
	def NextFlow()
	  if (@nextFlow==@flows.size)
	    return nil
	  end
    
	  flow=@flows[@nextFlow]
	  @nextFlow=@nextFlow+1
	  
	  return flow
	end
  
	def FlowsLeft
	  return @flows.size()-@nextFlow
	end
	
end
