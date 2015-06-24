#!/usr/bin/ruby

offset=-1

if ARGV.size>0
  $filestats=ARGV[0]
else
  $filestats="statlogs"
end

def sum_over_all_nodes(name)
	val=Array.new
	variance=Array.new

	sum=0
	sumv=0

	file=File.open($filestats,"r")

	last_part=false

	file.each_line do |line|
		if (line.include?(name))
			last_part=true
		else
		   if last_part
			if line.index("(")!=0
			   break
			end
			values = line.split(" ")
#			puts "New value #{values[2].to_f}"
			val << values[2].to_f
			#val << values[offset].delete("[],").to_f
			#if (values[-1].delete("[],").to_f == -1)
			#	variance << 0
			#else
		#		variance << values[-1].delete("[],").to_f
		#	end

		   end
		end

	end

#	puts "size #{val.size}"


 	if (val.size==0)
	   #return "0 -1"
	   return 0
	end

	val.each{ |a| sum+=a }
#	variance.each{ |b| sumv+=b }
	#retur = String.new((sum/val.size()).to_s + " " + (sumv/val.size()).to_s)
	retur = sum/val.size()
        return retur
end

def sum_over_all_nodes_var(name)
	val=Array.new
	variance=Array.new

	sum=0
	sumv=0

	file=File.open("statlogs","r")

	last_part=false

	file.each_line do |line|
		if (line.include?(name))
			last_part=true
		else
		   if last_part
			if line.index("(")!=0
			   break
			end
			values = line.split(" ")
#			puts "New value #{values[2].to_f}"
			#val << values[2].to_f
			val << values[-2].delete("[],").to_f
			if (values[-1].delete("[],").to_f == -1)
				variance << 0
			else
				variance << values[-1].delete("[],").to_f
			end

		   end
		end

	end

#	puts "size #{val.size}"


 	if (val.size==0)
	   #return "0 -1"
	   return 0
	end

	val.each{ |a| sum+=a }
	variance.each{ |b| sumv+=b }
	#retur = String.new((sum/val.size()).to_s + " " + (sumv/val.size()).to_s)
	retur = sumv/variance.size()
        return retur
end



tot_aggr=sum_over_all_nodes("counter measure = Aggregated")
tot_notaggr=sum_over_all_nodes("counter measure = NotAggregated")


if ((tot_notaggr+tot_aggr) > 0)
	printf("Aggr_level:#{100*tot_aggr/(tot_notaggr+tot_aggr)} 0\n")
end

tot_aggr=sum_over_all_nodes("counter measure = UseAggQueue") 
tot_notaggr=sum_over_all_nodes("counter measure = UseFreeFlowRateQueue") + sum_over_all_nodes("counter measure = UseFlowRateQueue") 

if ((tot_notaggr+tot_aggr) > 0)
	printf("Router_level:#{100*tot_aggr/(tot_notaggr+tot_aggr)} 0\n")
end
