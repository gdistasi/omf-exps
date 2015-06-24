#!/usr/bin/ruby


# Create a file for each kind of experiment that contains the result for the different aggregation delays.

class Experiment
        attr_accessor :values

	def initialize(routing, protocol)
		@routing=routing
		@protocol=protocol
		@values=Array.new
	end

	def key()
		"#{routing} #{protocol}"
	end

	def hash
		key().hash
	end

	def addSample(key,value)
		@values << Sample.new(key,value)
	end

	def equal?(other)
  		return (@routing==other.routing and @protocol==other.protocol)
	end

	def Sort!()
		@values.sort!
	end
	
	
	class Sample
	  
	        attr_accessor :key, :value
	  
		def initialize(key, value)
			@key=key
			@value=value
		end		
	
		def <=>(other)
		    return @key<=>other.key
		end
	end	
end


logDirs=ARGV

if ENV['WHAT'] == nil
    puts "Set WHAT environment variable (to Thr, Dl, Ls or Agg)"
    exit(1)
end

WHAT=ENV['WHAT']


EXTRACT=File.dirname(__FILE__)+"/extract.rb"
AGGEXTRACTOR=File.dirname(__FILE__)+"/aggregationstats.rb"

exps=Hash.new

logDirs.each do |dir|
  expName=File.basename(dir)
  
  elems=expName.split("_")
  delay=Float(elems[3])
  protocol=elems[5]
  routing=elems[1]

  key="#{routing} #{protocol}"
  if exps.has_key?(key) 
	exp=exps[key]
  else
	exp=Experiment.new(routing,protocol)
	exps[key]=exp
  end

  if WHAT=="Agg"
     result=`ruby #{AGGEXTRACTOR} #{dir}/statlogs`

     aggRatio=0
     result.each_line do |line|
     
       if line.include?("Aggr_level")
	 aggRatio=Float(line.split(/:| /)[1])
       end
	 
     end
                     
     exp.addSample(delay, aggRatio)

  else
    result=`ruby #{EXTRACT} #{dir}/result #{WHAT}`
  
    sum=0
    numSamples=0

    result.each_line do |line|
	  if line.include?("Time")
		  next
	  end
	  sum=sum+Float(line.split(" ")[1])
	  numSamples=numSamples+1
    end

    exp.addSample(delay, sum/numSamples)
  end
    
    
end 

exps.each do |key,exp|
  exp.Sort!
  file=File.open("#{key}-averaged.txt","w")
  file.puts("Time #{WHAT} Aggregate-flow")
  exp.values.each do |value|
    file.puts "#{value.key} #{value.value} #{value.value}"
  end
  
  file.close

end



