require './getoptlong'
require '/usr/local/bin/click.rb'

# Periodically check the routing table for changes.
# Write the changes on the specified log file.

class RoutingLogger

     def initialize
	@stack="Linux"
     end

     def Configure

    	opts = GetoptLong.new(
    	  	  ['--stack', '-s', GetoptLong::OPTIONAL_ARGUMENT],
		  ['--interval', '-i', GetoptLong::REQUIRED_ARGUMENT],
		  ['--logfile', '-l', GetoptLong::REQUIRED_ARGUMENT]
      	)

	

        opts.each do |opt, arg|
 
		#the host which gives topological information (usually the gateway), i.e. the host with the olsr plugin.
		if opt=="--stack"
		  @stack=arg
		end

		if opt=="--interval"
		  @interval=Integer(arg)
		end

		if opt=="--logfile"
		  @logfile=arg
		end


	end

	if (@logfile == nil or @interval == nil)
		$stderr.write("Please specify both --logfile  and --interval parameters.\n")
		exit(1)
	end

	@file=File.open(@logfile, "w+")

     end

     def Run
	line=""	

	@stop=false			
	thread=Thread.new{DoCollect()}
		
	while (line.chomp!="exit" )
		line = gets

		if (line.chomp=="exit")
			@stop=true
		else
			$stderr.write("Unknown command received: #{line}")
		end
		
	end	

	cnt=0
	while (thread.status!=false)
		sleep 1
		cnt=cnt+1
		if (cnt==6)
			$stderr.write("Error: the thread won't stop!\n")
			break
		end
	end

	log "Closing."

	@file.close

     end


     def DoCollect()
	rt=""

	getter=

	if (@stack=="Linux")
	   getter=LinuxRTable.new
	elsif (@stack=="Layer25")
	   getter=Layer25RTable.new
	else
	   $stderr.write("Stack #{@stack} not recognised.")
	   exit(1)
	end	

	startTime=Time.now
	
        while not @stop

		puts "Querying routing table..."
		
		newRt=getter.GetRoutingTable

		if (rt=="")
			log "======= INITIAL ROUTING TABLE ========="
		        log "Time: #{Time.now.to_s}"
			log "From start: #{Time.now-startTime}s"
			log(newRt)
			rt=newRt

		end

		if (newRt!=rt)
			log "======= ROUTING TABLE CHANGED ========="
		        log "Time: #{Time.now.to_s}"
			log "From start: #{Time.now-startTime}s"
			diff=GetDiff(newRt,rt)	

			if diff!=""			
				log "Added rules:"
				log diff
			end

			diff=GetDiff(rt,newRt)
			if diff!=""			
				log "Removed rules:"
				log diff
			end

			rt=newRt
		else

		end

		sleep(@interval)

	end
	
	rt.close

    end

	
    def log(str)

	if (str[-1]!="\n")
		str="#{str}\n"
	end

	@file.write(str)	
	@file.flush
    
    end

    def GetDiff(new,old)

	str=""
	new.each_line do |line|
		if not old.include?(line)
			str="#{str}#{line}"
		end
	end
	return str

    end

end



class LinuxRTable

	def GetRoutingTable
		rt=`/sbin/ip route show`
	end
	
	def close
	  
	end

end


class Layer25RTable
	def initialize()
	  @click=Click.new
	end
  
	def GetRoutingTable
		rt=""
	        firstPart=@click.ReadHandler("geslinks","get_links")
		firstPart.each_line do |line|
		    rt="#{rt}#{line.sub(/Bytes_sent:.*;/,"")}"
		end
	  
		rt="#{rt}\
		    #{@click.ReadHandler("flooder","get_topology")}"
	end
	
	def close
	  @click.close
	end

end



rlogger=RoutingLogger.new
rlogger.Configure
rlogger.Run



