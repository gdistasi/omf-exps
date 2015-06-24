require 'getExps.rb'


defaults="omf exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --stabilizeDelay 120"

exps = [ {"topo" => "topos/topoSimpleLuciaEndHosts", "links" => "topos/links_topoSimpleLuciaEndHosts", "id" => 1, "value" => "omf exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.1  --caOption \"0-1-2,1-1-2,S\" --stabilizeDelay 120 --initialAlgo MA --initialAlgoOption \"0-0-4,1-0-5,S\" ", "repetitions" => 1, "debug" => true },

{"topo" => "topos/topoSimpleLuciaEndHosts", "links" => "topos/links_topoSimpleLuciaEndHosts", "id" => 3, "value" => "omf exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.1 --caOption \"0-1-2,S\" --stabilizeDelay 120 --initialAlgo MA --initialAlgoOption \"0-0-4,1-0-2,S\" ", "repetitions" => 1, "debug" => true },

{"topo" => "topos/topoSimpleLuciaEndHosts", "links" => "topos/links_topoSimpleLuciaEndHosts", "id" => 1, "value" => "omf exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.1  --caOption \"0-1-2,1-1-2,S\" --stabilizeDelay 120 --initialAlgo MA --initialAlgoOption \"0-0-4,1-0-5,S\" ", "repetitions" => 5 },
    
{"topo" => "topos/topoSimpleLuciaEndHosts", "links" => "topos/links_topoSimpleLuciaEndHosts", "id" => 3, "value" => "omf exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.1 --caOption \"0-1-2,S\" --stabilizeDelay 120 --initialAlgo MA --initialAlgoOption \"0-0-4,1-0-2,S\" ", "repetitions" => 5 },

{"topo" => "topos/topoSimpleLuciaEndHosts", "links" => "topos/links_topoSimpleLuciaEndHosts", "id"=> 4, "value" => "omf exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.1 --caOption \"0-1-3,S\" --stabilizeDelay 120 ", "repetitions" => 4 },

{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts",  "id" => 9, "value" => "omf exec main.rb --  --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-4,5-1-4,S\" --stabilizeDelay 120  --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\" ","repetitions" => 1, "debug" => true  },
         
{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts", "id" => 10, "value" => "omf exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-2,S\" --stabilizeDelay 120 --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\"", "repetitions" => 1 ,  "debug" => true },

{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts",  "id" => "9bis", "value" => "omf exec main.rb --  --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-5,5-1-5,S\" --stabilizeDelay 120  --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\"" , "repetitions" => 1, "debug" => true  },

{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts",  "id" => "9bis", "value" => "omf exec main.rb --  --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-5,5-1-5,S\" --stabilizeDelay 120  --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\"" , "repetitions" => 2  },
         
{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts",  "id" => 9, "value" => "omf exec main.rb --  --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-4,5-1-4,S\" --stabilizeDelay 120  --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\"" , "repetitions" => 3  },
         
{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts", "id" => 10, "value" => "omf exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-2,S\" --stabilizeDelay 120 --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\" ", "repetitions" => 3  } 
]

initCaOption="0-0-3,0-1-4,1-0-2,1-1-5,2-0-3,2-1-5,3-0-1,3-1-3,4-0-1,4-1-6,5-0-1,5-1-4,6-0-2,6-1-4,7-0-2,7-1-6,8-0-3,8-1-4,9-0-5,9-1-6,10-0-3,10-1-5,11-0-1,11-1-2,12-0-4,12-1-5"
changes=[{ "changes" => ["12-4-7,5-4-7","3-3-4","0-3-5","5-1-6","8-4-2"], "description" => "A" }]
topo="topos/topoOrbit3"
links="topos/links_topoOrbit3"
demands="0.1,0.1,0.1,0.1,0.1,0.1"

#changes.each do |ch|
  #GetExps(defaults, initCaOption,  ch["changes"], ch["description"], topo , links, demands, 2).each do |exp|
   #     exps << exp
  #end
#end