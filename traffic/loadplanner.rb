# Create a test scenario
# It divides the experiment time in numIntervals intervals
# For each interval, it defines a bitrate between 0 and maxBitrate
# Can return the flow to be started at the beginning of each interval in order to get
# in each interval the desired throughput (the desired throughput is obtained by summing up a certain number of flows)-

require 'traffic/flow.rb'

class LoadPlanner

  attr_accessor :sender, :receiver


  def old_initialize(numChanges, duration, maxBitrate, sender, receiver, docalc=true)
    @numIntervals=numChanges+1
    @duration=duration
    @maxBitrate=maxBitrate
    @times=Array.new
    @bitrates=Array.new
    #@alpha=0.1
    #@beta=0.4
    @flows=Array.new

    #duration of an interval where the bitrate is kept constant
    @interval=@duration/@numIntervals

    
    @sender=sender
    @receiver=receiver
    
    @times << 0
    
    (1..(@numIntervals-1)).each do |time|
      @times << time*@interval  
    end

    
    if (docalc)
      CalcBitrates()
      Plan()
    end
      
  end

  #set the demands statically
  #demands are specified in Mbit/s
  def initialize(demand, duration, sender_id, receiver_id)
    
    old_initialize(0, duration, 0, sender_id, receiver_id, false) 
    
    @bitrates <<  demand*1024
    
    i=0
    @bitrates.each do  |bit|
      puts "#{@times[i]}s #{bit}kbit/s"
      i=i+1
    end
        
    Plan()
    
  end
  
  
  
  def GetTimes
    return @times
  end

  def GetBitrates
    return @bitrates
  end
  
  def GetFlows()
    return @flows
  end
  

  
  private

  #Defines the bitrate for each interval
  def CalcBitrates

    @bitrates << rand*@maxBitrate
    
    (1..(@numIntervals-1)).each do |n|
      @bitrates << rand*@maxBitrate
    end
    
    puts "Load profile between #{@sender.id} and #{@receiver.id}"
    
    i=0
    @bitrates.each do  |bit|
      puts "#{@times[i]}s #{bit}kbit/s"
      i=i+1
    end
    
  end
  
  #Plans the flows to be started and terminated when each interval starts
  def Plan
    
    aggregate = AggregatorFlows.new
    
    min = @bitrates.sort[0]
    
    #puts "Min bitrate: #{min}"
    #puts "Max bitrate: #{@maxBitrate}"
    
    
    aggregate.Push(Flow.new(0, min, @sender, @receiver))
    
    if (@bitrates[0]-min)>0
      aggregate.Push(Flow.new(0, @bitrates[0]-min, @sender, @receiver))
    end
      
    #puts "Check: #{aggregate.Bitrate()} #{@bitrates[0]}"
      
    
    (1..(@numIntervals-1)).each do |n|
	diff=@bitrates[n] - @bitrates[n-1]
	#a new flow needs to be added
	if (diff>0)
	  flow=Flow.new(n*@interval, diff, @sender, @receiver)
	  aggregate.Push(flow)
	# some flows need to be added
	else
	  #remove flows from the stack until we get equal or less to the desired bitrate
	  while (aggregate.Bitrate()>@bitrates[n])
	    flow=aggregate.Pop
	    flow.SetEnd(n*@interval)
	  end
	  if (aggregate.Bitrate()<@bitrates[n])
	    flow=Flow.new(n*@interval, @bitrates[n]-aggregate.Bitrate(), @sender, @receiver)
	    aggregate.Push(flow)
	  end
	  
	end
	
	#puts "Check: #{aggregate.Bitrate()} #{@bitrates[n]}"
      
     end
    
     #pop the remaining flows
     while (aggregate.size()>0)
	flow=aggregate.Pop()
	flow.SetEnd(@duration)
     end
     
     @flows=aggregate.GetFlows
     
  end
       
end

class LoadPlannerHelper
  
  def initialize(seed, numIntervals, duration, maxBitrate)
    @numIntervals=numIntervals
    @duration=duration
    @maxBitrate=maxBitrate
    srand(seed)
  end
  
  def MakeLoadPlanner(sender, receiver)
    return LoadPlanner.new(@numIntervals, @duration, @maxBitrate, sender, receiver)
  end
  
  
end

if __FILE__ == $0
  planner = LoadPlanner.new(0.5, 10, 20, 5000)
  flows = planner.GetFlows

  flows.each do |flow|
    puts "Flow:"
    puts "Start time: #{flow.start}"
    puts "Stop time: #{flow.stop}"
    puts "Bitrate: #{flow.bitrate}"
    puts ""
  end
end


