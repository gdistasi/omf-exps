
topo="topos/topoSb2"
env="ORBIT-SB3"


# (the following are exp 1, exp 3 and exp4)
exps = [ {"id" => 1, "value" => "omf exec main.rb -- --topo #{topo} --stack Olsrd --extraDelay 40 --algo MA --demands 0.1 --links topos/links_topoSimpleLucia  --caOption \"0-1-2,1-1-2,S\" --stabilizeDelay 120 --olsrdebug 3 --env #{env} --initialAlgo MA --initialAlgoOption \"0-0-4,1-0-5,S\" "},
    
{"id" => 2, "value" => "omf exec main.rb -- --topo --topo #{topo} --stack Olsrd --extraDelay 40 --algo MA --demands 0.1 --links topos/links_topoSimpleLucia  --caOption \"0-1-2,S\" --stabilizeDelay 120 --olsrdebug 3 --initialAlgo MA --initialAlgoOption \"0-0-4,1-0-2,S\" --env #{env}"},

{"id"=> 4, "value" => "omf exec main.rb -- --topo --topo #{topo} --stack Olsrd --extraDelay 40 --algo MA --demands 0.1 --links topos/links_topoSimpleLucia  --caOption \"0-1-3,S\" --stabilizeDelay 120 --olsrdebug 3 --env #{env}" }
  
]

exps7nodes = [ {"id" => 9, "value" => "omf exec main.rb -- --topo topos/topoLucia0 --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05 --links topos/links_topoLucia0  --caOption \"3-1-4,5-1-4,S\" --stabilizeDelay 120  --olsrdebug 4 --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\" --env #{env}" },                  
                 {"id" => 10, "value" => "omf exec main.rb -- --topo topos/topoLucia0 --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05 --links topos/links_topoLucia0  --caOption \"3-1-2,S\" --stabilizeDelay 120 --olsrdebug 4 --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\" --env #{env} " } ]
         
system("bash ./scripts/del_logs.sh")

repetitions=4

protocols=["TCP","UDP"]

invalidations = ["yes", "no"]

profiles = ["hysteresis", "standard" ]

repetitions.times do |rep|

  profiles.each do |profile|
  
    exps.each do |exp|
      
      invalidations.each do |inv|
               
	protocols.each do |protocol|
  
	  logdir="autoexps2/test_#{exp["id"]}_protocol_#{protocol}_inv_#{inv}_profile_#{profile}_rep_#{rep}"
	
	  puts logdir
	
	  if not File.exists?("#{logdir}/completed")
	    system("#{exp["value"]} --protocol #{protocol} --invalidateLinks #{inv} --startTcpdump yes --profile #{profile}")
	    if ($?==0)
	      sleep(4)
	      system("bash ./scripts/get_results.sh #{logdir}")
	      sleep(4)
	      system("touch #{logdir}/completed")
	    else
	      $stderr.puts("Experiment failed!")
	    end
	
	  end
	
       end
    
      end
    
    end
  
  end

end

