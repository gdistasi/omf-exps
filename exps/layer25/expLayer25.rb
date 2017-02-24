
defaults="--extraDelay 60 --stabilizeDelay 120 --channels 1,6,11"
#--channels 36,48,149,157,165,44,161"
#--setAp 00:11:22:33:44:55"
initCaOption="0-0-3,0-1-4,1-0-2,1-1-5,2-0-3,2-1-5,3-0-1,3-1-3,4-0-1,4-1-6,5-0-1,5-1-4,6-0-2,6-1-4,7-0-2,7-1-6,8-0-3,8-1-4,9-0-5,9-1-6,10-0-3,10-1-5,11-0-1,11-1-2,12-0-4,12-1-5"
topo="bufferbloat/topology.xml"
extraProperties=""
protocols=["TCP", "UDP"]
repetitions = 1
stacks = ["Layer25"]
#$ca_algos_def = [ {"name" => "MA" , "option" => initCaOption} ]
#{"name" => "FCPRA", "option" => 7}, 
aggregation = [ "no" ]
weigth_flowrates_def = [ "no"]
info="null"
demands=[1, 10, 24, 54]


protocols.each do |proto|
    stacks.each do |stack|
        aggregation.each do |agg|
            weigth_flowrates_def.each do |wf|
                demands.each do |demand|
                    (1..repetitions).each do |rep|
                        exp = { "protocol" => proto, "stack" => stack, "aggregation_enabled" => agg, "weigthFlowrates" => wf, "defaults" => defaults, "scriptFile" => "layer25/testLayer25.rb", "demands" => demand, "repetition" => rep, "info" => "firstLayer25", "topo" => topo }
                        $EXPS << exp
                
                    end
                end
            end
        end
    end
end




