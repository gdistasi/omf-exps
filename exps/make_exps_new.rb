#!/usr/bin/ruby -w

env=ENV['ENV']

if (env==nil or env.strip=="")
  env="ORBIT"
  ENV['ENV']=env
end

#update
puts "Updating sources. Type the password if asked."
system("bash -c \"cd ~; ./update_l2r.sh\"")

if ARGV[0]==nil
  require 'scripts/expCommMagReview.rb'
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

first_exp=true

$EXPS.each do |exp|

   if exp["repetitions"] != nil
     repetitions = exp["repetitions"]
   else
     if ($repetitions_def==nil)
       $repetitions_def=1
     end
     repetitions=$repetitions_def
   end
     
   repetitions.times do |rep|

   if exp["invalidations"]!=nil
       invalidations=exp["invalidations"]
   else
      invalidations=$invalidations_def
   end
      
   invalidations.each do |inv|
     
    if exp["profiles"]!=nil
      profiles=exp["profiles"]
    else
      profiles=$profiles_def
    end
    
    profiles.each do |profile|
        
        if exp["protocols"]!=nil
          protocols=exp["protocols"]
        else
          protocols=$protocols_def
        end
     
	protocols.each do |protocol|
  
	  logdir="autoexps/test_#{exp["id"]}_protocol_#{protocol}_inv_#{inv}_profile_#{profile}_rep_#{rep}"
	
	  if exp["info"] != nil 
      	      logdir="#{logdir}_info_#{exp["info"].strip}"
	  elsif ENV['EXPINFO'] != nil and ENV['EXPINFO'].strip!=""
	      logdir="#{logdir}_info_#{ENV['EXPINFO'].strip}"
	  else
	      logdir="#{logdir}_info_null"
	  end
	  
	  if exp["debug"]!=nil and exp["debug"]==true
	      
	      logdir="#{logdir}_debug_on"
	      debug=true
	  else
	      debug=false
	  end
	  
	  puts logdir
	
	  if not File.exists?("#{logdir}/completed")
	    if exp["topo"] != topo or debug!=topo_debug
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
		 
		 #system("bash ./update_ath5k.sh")
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
	      
	    system("bash ./scripts/del_logs.sh")
	    system("rm -rf #{logdir}")
	    
	    omf_pid=nil
	    
	    #execute OMF in a thread
	    omf_t = Thread.new do
	      
	      cmd = "#{exp["value"]} --protocol #{protocol} --invalidateLinks #{inv} --startTcpdump yes --profile #{profile}  --topo #{exp["topo"]} --links #{exp["links"]} --olsrdebug #{olsrdebuglevel} --env #{env} --avoidTcpRst yes"
	      
	      if exp["extraProperties"]!=nil
		cmd="#{cmd} #{exp["extraProperties"]}"
	      end
	      
	      puts cmd
	      
	      puts "Max duration #{max_duration}"
	      
	      IO.popen(cmd) do |omf| 
		
		omf_pid=omf.pid
		
		omf.each do |line|
		  if line.downcase.include?("exception") or line.downcase.include?("giving up on node")
		      puts line
		      throw "Error in executing omf: #{line}"
		  end
		  puts line
		end
	      end

	      if $?!=0
		  throw "Error: exit value was: #{$?}"
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
		  ok=true
		  break
	      end
	      
	      #exited with an exception
	      if (omf_t.status == nil)
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
	      system("bash ./scripts/get_results.sh #{logdir}")
	      sleep(4)
	      system("touch #{logdir}/completed")
	    else
	      $stderr.puts("Experiment failed!")
	    end

	    system("bash -c \"(sleep 270; rsync -r #{logdir} --exclude '*tcpdump*' orbit@143.225.229.59:exps/ ) &\"")
	    
	    $stderr.puts("Starting next exp in 3 sec.")
	    sleep(3)

	      
	  end
	
       end
    
      end
    
    end
  
  end

end
