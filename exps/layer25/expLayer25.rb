
#require 'scripts/getExps.rb'

defaults="--extraDelay 60 --stabilizeDelay 120 --channels 36,48,149,157,165,44,161 --setAp 00:11:22:33:44:55"

$EXPS = Array.new

initCaOption="0-0-3,0-1-4,1-0-2,1-1-5,2-0-3,2-1-5,3-0-1,3-1-3,4-0-1,4-1-6,5-0-1,5-1-4,6-0-2,6-1-4,7-0-2,7-1-6,8-0-3,8-1-4,9-0-5,9-1-6,10-0-3,10-1-5,11-0-1,11-1-2,12-0-4,12-1-5"
topo="topos/topoOrbit4-l2r"
links="topos/links_topoOrbit4-l2r"
demands="20,20,20,20"
extraProperties=""


$protocols_def=["UDP"]
$repetitions_def = Integer(ENV['REPETITIONS'])
$stacks_def = ["Layer25"]
$ca_algos_def = [ {"name" => "MA" , "option" => initCaOption} ]
#{"name" => "FCPRA", "option" => 7}, 
$aggregations_def = [ "no" ]
$weigth_flowrates_def = [ "yes"]
info="null"

exp = { "value" => "#{defaults} --demands #{demands}", "id" => "#{topo}_descr_newL2r", "topo" => topo, "links" => links, "repetitions" => $repetitions_def,  "info" => info,  "max_duration" => 10  }

$EXPS << exp



