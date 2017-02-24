#!/usr/bin/ruby 

require 'find'


if ENV['ENV']==nil then
   $stderr.puts "The following env variables is needed: ENV" 
    exit(1)
end

env=ENV['ENV']

if env=="MININET" then
    home=ENV['MININETHOME'] 
    if home==nil or home=="" then
       $stderr.puts "MININETHOME environment variable must be set!"
       exit(1)
    end
end
    


#update
#puts "Updating sources. Type the password if asked."
#system("bash -c \"cd ~; ./update_l2r.sh\"")


if ARGV.size!=1 then
   puts("Usage: make_exps.rb expsFile.rb")
   exit(1)
end

$EXPS = Array.new

require ARGV[0]



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

expDone=false


$EXPS.each do |exp|
    
    exp["env"]=env

   if exp["repetitions"] != nil
     repetitions = exp["repetitions"]
   else
     repetitions=1
   end
      
      if expDone then
        system("../scripts/restartOmfResctl.py #{exp["topo"]} #{home}") 
        system("sudo rm -f /tmp/default*xml /tmp/default*log /tmp/itg*log /tmp/ditg* /tmp/*pcap /tmp/tcStats")
      end
      
      if exp["scriptFile"]==nil then
         $stderr.puts "Experiment dictionary must have a scriptFile key."
         exit(1)
      end
      
      if exp["info"] == nil then
         $stderr.puts "Experiment dictionary must have a info key."
         exit(1)
      end
      
      logdir="autoexps/info_#{exp["info"]}"
      
      expDone=false
      
      exp.keys.each do |key|
         if key=="repetition" or key=="info" or key=="defaults" then
             next
         end
         value=exp[key]
         if value.class.to_s=="String" and value.include?("_") then
                valueS=value.dup
                valueS["_"]=""
         elsif value.class.to_s=="String" and value.include?("/") then
                valueS=value.dup
                valueS["/"]="-"
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
      system("mkdir -p #{logdir}")
	
	  if not File.exist?("#{logdir}/completed")
          
        expDone=true  
          
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
        
        system("rm -rf #{logdir}/*")
	    
        
	    omf_pid=nil
	            
	    #execute OMF in a thread
	    omf_t = Thread.new do
        
          cmd = "omf-5.4 exec #{exp["scriptFile"]} -- #{exp["defaults"]}"
          
          exp.keys.each do |key|
             if key=="defaults" or key=="info" or key=="scriptFile" then
                 next
             else
                 if exp[key]!=nil and exp[key]!="" then
                    cmd="#{cmd} --#{key} #{exp[key]}"
                 else
                    $stderr.puts "Warning: exp key #{key} = \"#{exp[key]}\"" 
                 end
             end
              
          end

	      puts cmd
	      
	      #puts "max duration #{max_duration}"
	      
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

          $?
          
        end
	    #checking the OMF thread
        
        
	    start=Time.new
	    ok=false
	    
	    k=0
	    
        
	    while true
            
	      now=Time.new
	                
	      #thread ended
          if omf_t.stop? then
            omfExitValue = omf_t.value
            if omfExitValue==0
                $stderr.puts "Omf expc exited normally."
                ok=true
            else
            #exited with an exception
                $stderr.puts "Omf expc exited with an exception (return value: #{omfExitValue})"
                ok=false
            end
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
            ok=false
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
          puts "Executing: ../scripts/get_results.sh #{logdir}"
          puts `pwd`
	      system("../scripts/get_results.sh #{logdir}")
	      sleep(4)
	    end
        
        ditg_files_paths = []
        
        Find.find(logdir) do |path|
            ditg_files_paths << path if path =~ /ditg.*log/
        end
        if ditg_files_paths.size()==0 then
           ok=false 
           $stderr.print "No ditg log files!"
        end
        
        ditg_files_paths.each do |file|
             if File.size(file)==0 then
                ok=false 
                $stderr.print "Ditg log file size = 0!"
             end
        end
        
        if not ok
	      $stderr.puts("Experiment failed!")
        else
   	      system("touch #{logdir}/completed")
        end

	    #system("bash -c \"(sleep 250; rsync -r #{logdir} --exclude '*tcpdump*' orbit@143.225.229.59:exps/ ) &\"")
	    
	    $stderr.puts("Starting next exp in 3 sec.")
	    sleep(3)

	      
	  end
    
end
