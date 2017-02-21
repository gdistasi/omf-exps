#!/usr/bin/ruby -w

env=ENV['ENV']

if (env==nil or env.strip=="")
  env="ORBIT"
  ENV['ENV']=env
end


home="/home/gdistasi/" if env=="ORBIT"
home="/home/mininet/mininetOmf" if env=="MININET"

#update
#puts "Updating sources. Type the password if asked."
#system("bash -c \"cd ~; ./update_l2r.sh\"")

if ARGV[0]==nil
  require 'bufferbloatExps.rb'
else
  require ARGV[0]
end

if ENV["TOPO_LOADED"]!=nil and  ENV["TOPO_LOADED"]!=""
  topo=ENV["TOPO_LOADED"]
else
  topo="" 
end

if ENV["TOPO_LOADED_DEBUG"]!=nil and  ENV["TOPO_LOADED_DEBUG"]!=""
  topo_debug=true
else
  topo_debug=false
end
  
#start http server
system("python -m SimpleHTTPServer > http.log 2>&1 &")

#create experiments directory
system("mkdir -p autoexps")

first_exp=trueres

$EXPS.each do |exp|

   if exp["repetitions"] != nil
     repetitions = exp["repetitions"]
   else
     repetitions=1
   end
   
      system("../../scripts/restartOmfResctl.py #{exp["topo"]} #{home}") 
      system("rm -f /tmp/default*xml /tmp/default*log /tmp/itg*log /tmp/ditg* /tmp/*pcap /tmp/tcStats")
      
      logdir="autoexps/bufferbloat_0"
      
      exp.keys.each do |key|
         if key=="repetition" or key=="value" then
             next
         end
         value=exp[key]
         if value.class.to_s=="String" and value.include?("_") then
                valueS=value.dup
                valueS["_"]=""
         else
            valueS=value 
         end
            
         keyS=key.dup
         if keyS.class.to_s=="String" and keyS.include?("_") then
            keyS["_"]=""
         end
         
         if value!=nil and value!="" then
            logdir="#{logdir}_#{keyS}_#{valueS}"
         end
      end
      
      logdir="#{logdir}_repetition_#{exp["repetition"]}"
      
	  if exp["debug"]!=nil and exp["debug"]==true
	      logdir="#{logdir}_debug_on"
	      debug=true
	  else
	      debug=false
	  end
	  
	  puts logdir
	
	  if not File.exist?("#{logdir}/completed")
          
	    if (exp["topo"] != topo or debug!=topo_debug) and env["ENV"]=="ORBIT"
		 if (debug)
		   ENV['DEBUG']="1"
		   system("./prepare.sh #{exp["topo"]}")
   		   ENV['DEBUG']=""
		 else
		  system("./prepare.sh #{exp["topo"]}")
		 end
		  
		 sleep(120)
		 topo=exp["topo"]
 		 ENV['TOPO_LOADED']=exp["topo"]
		 topo_debug=debug
		 
	    end

	    if (exp["olsrdebuglevel"]!=nil)
	      olsrdebuglevel=exp["olsrdebuglevel"]
	    elsif (debug)
              olsrdebuglevel=9
            else
              olsrdebuglevel=0
            end
	    
	    if exp["max_duration"]!=nil
	      max_duration=exp["max_duration"]
	    else
	      max_duration=14
	    end
	    
        if env=="ORBIT" then
            system("bash ../../scripts/del_logs.sh")
        end
        
        system("rm -rf #{logdir}")
	    
        
	    omf_pid=nil
	    
	    #execute OMF in a thread
	    omf_t = Thread.new do
	      
	      cmd = "#{exp["value"]} --protocol #{exp["protocol"]} --qdisc #{exp["qdisc"]} --startTcpdump yes   --topo #{exp["topo"]}  --olsrdebug #{exp["olsrdebuglevel"]} --env #{env} --bottleneckRate #{exp["bottleneckRate"]} --rate #{exp["rate"]}"
	      
	      if exp["extraProperties"]!=nil
            cmd="#{cmd} #{exp["extraProperties"]}"
	      end
	      
	      puts cmd
	      
	      puts "max duration #{max_duration}"
	      
	      IO.popen(cmd) do |omf|
		
            omf_pid=omf.pid
            		
            omf.each do |line|
                if line.downcase.include?("exception") or line.downcase.include?("giving up on node")
                    puts line
                    throw "Error in executing omf: #{line}"
                end
                puts line
            end
         
            if $?!=0
                throw "Error: exit value was: #{$?}"
            end
	      
          end
        end
	    #checking the OMF thread
        
	    start=Time.new
	    ok=false
	    
	    k=0
	    
	    while true
            
	      now=Time.new
	      
	      #exited normally
	      if (omf_t.status == false)
            $stderr.puts "Omf expc exited normally."
            ok=true
            break
	      end
	      
	      #exited with an exception
	      if (omf_t.status == nil)
            $stderr.puts "Omf expc exited with an exception."
            break
	      end
	      
	      if (now-start > 110 and first_exp and false)
            puts "Killing first experiment!"
            system("pkill -P #{omf_pid}")
            sleep(10)
            system("pkill -9 -P #{omf_pid}")
            first_exp=false
            break
	      end
	      
	      
	      #taking too long (more than XX minutes)
	      if (now-start > 60*max_duration)
            puts "Experiment is taking too long! Killing!"
            system("pkill -P #{omf_pid}")
            sleep(10)
            system("pkill -9 -P #{omf_pid}")
            break
	      end
	      
	      sleep(5)
	      
	      
	      if (k%20==0) and ENV['ENV']=="ORBIT"
            topoOffNodes=`cat topoOff`
            system("omf tell -a offh -t #{topoOffNodes} >/dev/null 2>&1 &")
	      end
	      k=k+1
	      
	      sleep(2)
	      #puts omf_pid
	    end
	      
	    if (ok)
	      sleep(4)
	      system("../../scripts/get_results.sh #{logdir}")
	      sleep(4)
	      system("touch #{logdir}/completed")
	    else
	      $stderr.puts("Experiment failed!")
	    end

	    #system("bash -c \"(sleep 250; rsync -r #{logdir} --exclude '*tcpdump*' orbit@143.225.229.59:exps/ ) &\"")
	    
	    $stderr.puts("Starting next exp in 3 sec.")
	    sleep(3)

	      
	  end
    
end
