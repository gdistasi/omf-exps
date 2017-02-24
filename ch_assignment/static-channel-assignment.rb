


defProperty('caAlgo', "FCPRA", "Channel Assignment algorithm")
defProperty('caAlgoOption', "2", "option for the channel assignment")
defProperty('caserverId', nil, "Caserver id")

# Assign the channels to network nodes' interfaces based on the given initialDemands and using the initialAlgo and numChannels.
# Supported algorithms are FCPRA and OneChannel.
class StaticChannelAssignment 

  def initialize(orbit)
    @orbit=orbit
  end
  
  
  def InstallApplications
   
  end


  def Start

  @orbit.GetNodes().each do |node| 
      node.GetInterfaces().each do |ifn|
	if (ifn.IsWifi()) then
	      @orbit.AssignChannel(node, ifn, ifn.GetChannel())
	end
	
      end
      
    end
    
  end

end 



