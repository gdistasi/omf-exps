require 'time'

#OBSOLETE!!

def GetTimes(dir)

  first=true
  res=""

  time0=nil


  File.open("#{dir}/node19-7.grid.orbit-lab.org/caagent.log").each_line do |line|
    
  if not line.include?("Received CHANNEL CHANGE")
	next
  end
    
  #`cat #{dir}/node19-7.grid.orbit-lab.org/caagent.log | grep -a \"Received CHANNEL CHANGE\"`.each_line do |line|
  
  if first
    first=false
    next
  end
  
  #puts line
  timestr=line.split(" ")[3]
  #puts timestr
  time=Time.utc(1,1,1,timestr.split(":")[0],timestr.split(":")[1],timestr.split(":")[2])

  if (time0==nil)
    time0=time
    res=("30.0 ")
  else
    diff=time-time0+30
    res="#{res} #{diff}"
  end
  
  end

  return res
  
end

if __FILE__ == $0
  puts GetTimes(ARGV[0])
end

