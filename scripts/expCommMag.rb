require 'scripts/getExps.rb'

defaults="omf-5.3 exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --stabilizeDelay 120 --channels 36,48,149,157,165,44,161"

$EXPS = Array.new

$EXPS2 = [ 
  
{"topo" => "topos/topoSimpleLuciaEndHosts", "links" => "topos/links_topoSimpleLuciaEndHosts", "id" => "1-setAp", "value" => "omf-5.3 exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.1  --caOption \"0-1-2,1-1-2,S\" --stabilizeDelay 120 --initialAlgo MA --initialAlgoOption \"0-0-4,1-0-5,S\" ", "repetitions" => 2, "protocols" => ["UDP"], "profiles" =>  ["standard"], "debug" => true, "info" => "lq-fixed", "extraProperties" => "--setAp 11:11:11:11:11:11", "olsrdebuglevel" => 0 },

#{"topo" => "topos/topoSimpleLuciaEndHosts", "links" => "topos/links_topoSimpleLuciaEndHosts", "id" => 3, "value" => "omf-5.3 exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.1 --caOption \"0-1-2,S\" --stabilizeDelay 120 --initialAlgo MA --initialAlgoOption \"0-0-4,1-0-2,S\" ", "repetitions" => 1, "debug" => true,  "protocols" => [ "TCP" ], "invalidations" => ["yes","no"], "profiles" =>  ["standard", "hysteresis"] },

#{"topo" => "topos/topoSimpleLuciaEndHosts", "links" => "topos/links_topoSimpleLuciaEndHosts", "id" => 1, "value" => "omf-5.3 exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.1  --caOption \"0-1-2,1-1-2,S\" --stabilizeDelay 120 --initialAlgo MA --initialAlgoOption \"0-0-4,1-0-5,S\" ","repetitions" => 4, "profiles" => ["standard"], "info" => "lq-fixed", "olsrdebuglevel" => 0 },
    
{"topo" => "topos/topoSimpleLuciaEndHosts", "links" => "topos/links_topoSimpleLuciaEndHosts", "id" => "3-setAp", "value" => "omf-5.3 exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.1 --caOption \"0-1-2,S\" --stabilizeDelay 120 --initialAlgo MA --initialAlgoOption \"0-0-4,1-0-2,S\" ", "repetitions" => 2, "info" => "lq-fixed" , "extraProperties" => "--setAp 11:11:11:11:11:11", "olsrdebuglevel" => 0 },

#{"topo" => "topos/topoSimpleLuciaEndHosts", "links" => "topos/links_topoSimpleLuciaEndHosts", "id"=> "4-setAp", "value" => "omf-5.3 exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.1 --caOption \"0-1-3,S\" --stabilizeDelay 120", "repetitions" => 2, "info" => "lq-fixed","profiles" =>  ["standard"], "olsrdebuglevel" => 0, "protocols" => ["UDP", "TCP"] },

#{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts",  "id" => 9, "value" => "omf-5.3 exec main.rb --  --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-4,5-1-4,S\" --stabilizeDelay 120  --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\" ","repetitions" => 1, "debug" => true  },
         
#{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts", "id" => 10, "value" => "omf-5.3 exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-2,S\" --stabilizeDelay 120 --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\"",  "debug" => true },

#{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts",  "id" => "9bis", "value" => "omf-5.3 exec main.rb --  --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-5,5-1-5,S\" --stabilizeDelay 120  --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\"" , "repetitions" => 2, "profiles" => ["standard"], "info" => "lq-fixed"  },

#{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts",  "id" => "9bis", "value" => "omf-5.3 exec main.rb --  --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-5,5-1-5,S\" --stabilizeDelay 120  --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\"" , "repetitions" => 1  },
  
#{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts",  "id" => "9diff", "value" => "omf-5.3 exec main.rb --  --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-4,5-1-4,S\" --stabilizeDelay 120  --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-6,0-1-4,1-0-6,1-1-3,2-0-2,2-1-5,3-0-3,4-0-4,5-0-2,6-0-5,S\"", "profiles" => ["standard", "hysteresis"], "repetitions" => 4 , "info" => "lq-fixed" },
  
{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts",  "id" => "9diff-setAp", "value" => "omf-5.3 exec main.rb --  --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-4,5-1-4,S\" --stabilizeDelay 120  --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-6,0-1-4,1-0-6,1-1-3,2-0-2,2-1-5,3-0-3,4-0-4,5-0-2,6-0-5,S\"", "profiles" => ["standard", "hysteresis"], "repetitions" => 3 , "info" => "lq-fixed", "extraProperties" => "--setAp 11:11:11:11:11:11" },
         
#{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts", "id" => "10diff", "value" => "omf-5.3 exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-2,S\" --stabilizeDelay 120 --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-6,0-1-4,1-0-6,1-1-3,2-0-2,2-1-5,3-0-3,4-0-4,5-0-2,6-0-5,S\"", "profiles" => ["standard", "hysteresis"], "info" => "lq-fixed", "repetitions" => 2 },
  
{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts", "id" => "10diff-setAp", "value" => "omf-5.3 exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-2,S\" --stabilizeDelay 120 --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-6,0-1-4,1-0-6,1-1-3,2-0-2,2-1-5,3-0-3,4-0-4,5-0-2,6-0-5,S\"", "profiles" => ["standard", "hysteresis"], "info" => "lq-fixed", "repetitions" => 3, "extraProperties" => "--setAp 11:11:11:11:11:11" }
  
#{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts",  "id" => 9, "value" => "omf-5.3 exec main.rb --  --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-4,5-1-4,S\" --stabilizeDelay 120  --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\"", "repetitions" => 2, "profiles" => ["standard"], "info" => "lq-fixed"   },
  
#{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts",  "id" => 9, "value" => "omf-5.3 exec main.rb --  --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-4,5-1-4,S\" --stabilizeDelay 120  --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\"", "repetitions" => 4, "profiles" => ["hysteresis"], "info" => "lq-fixed", "protocols" => ["UDP"]   },
         
#{"topo" => "topos/topoLucia0EndHosts", "links" => "topos/links_topoLucia0EndHosts", "id" => 10, "value" => "omf-5.3 exec main.rb -- --stack Olsrd --extraDelay 40 --algo MA --demands 0.05,0.05  --caOption \"3-1-2,S\" --stabilizeDelay 120 --biflow yes --initialAlgo MA --initialAlgoOption \"0-0-2,0-1-4,1-0-2,1-1-3,2-0-2,2-1-3,3-0-3,4-0-4,5-0-2,6-0-3,S\" " , "repetitions" => 2, "profiles" => ["standard","hysteresis"], "info" => "lq-fixed"  } 
  
  ]

$EXPS2.each do |exp|
$EXPS << exp  
end


initCaOption="0-0-3,0-1-4,1-0-2,1-1-5,2-0-3,2-1-5,3-0-1,3-1-3,4-0-1,4-1-6,5-0-1,5-1-4,6-0-2,6-1-4,7-0-2,7-1-6,8-0-3,8-1-4,9-0-5,9-1-6,10-0-3,10-1-5,11-0-1,11-1-2,12-0-4,12-1-5"
topo="topos/topoOrbit4"
links="topos/links_topoOrbit4"
demands="0.05,0.05,0.05,0.05,0.05,0.05"
extraProperties="--setAp 11:11:11:11:11:11"


changes_0=[
	# { "values" => [ "12-4-7,5-4-7","3-3-4","0-3-5", "5-1-6", "8-4-2"], "description" => "A" },
         #{ "values" => [ "8-4-2", "0-4-1", "10-3-4", "1-5-7,12-5-7,10-5-7", "6-2-6" ], "description" => "B" },
	# { "values" => [ "5-1-6", "11-2-5", "3-3-4", "6-2-7,7-2-7", "0-4-6" ], "description" => "C" },
         { "values" => [ "0-4-1", "10-3-4", "2-5-6", "3-3-4", "5-1-6" ], "description" => "complex1" },
	 { "values" => [ "2-5-6", "0-4-1", "3-3-5,8-3-5",  "6-2-6", "1-5-7,12-5-7,10-5-7" ], "description" => "mixed1" }
  ]


changes_1=[
  { "values" => [ "3-3-5,8-3-5", "3-1-2", "0-4-1",  "4-6-7,7-6-7,9-6-7", "6-2-7" ], "description" => "mixed2" }   
]

changes_2=[
   { "values" => [ "5-1-6", "11-2-5", "3-3-4", "6-2-7,7-2-7", "10-3-4" ], "description" => "mixed3" }
]

#changes_3=[
#     { "values" => [ "5-1-6", "11-2-5", "3-3-4", "6-2-7,7-2-7", "0-4-6" ], "description" => "mixed4" }
#  ]

$EXPS << GetComplexExpAllInOne(defaults, initCaOption,  changes_0, "complex1-and-mixed1", topo, links, demands, 2, extraProperties, "setAp")
$EXPS << GetComplexExpAllInOne(defaults, initCaOption,  changes_1, "mixed2-repetead", topo, links, demands, 1, extraProperties, "setAp")
$EXPS << GetComplexExpAllInOne(defaults, initCaOption,  changes_2, "mixed3-repeated", topo, links, demands, 1, extraProperties, "setAp")



old_changes=[
	 { "values" => [ "12-4-7,5-4-7","3-3-4","0-3-5", "5-1-6", "8-4-2"], "description" => "A" },
         { "values" => [ "8-4-2", "0-4-1", "10-3-4", "1-5-7,12-5-7,10-5-7", "6-2-6" ], "description" => "B" },
	 { "values" => [ "5-1-6", "11-2-5", "3-3-4", "6-2-7,7-2-7", "0-4-6" ], "description" => "C" }
        ]

changes_single = [ "5-1-6","6-2-5,7-2-5","10-3-4" ]
changes_double = [ "4-6-2,9-6-1","5-1-3,4-1-3,3-3-4", "10-5-2,6-2-5,7-2-5" ]
changes_triple = [ "12-4-3,5-4-3,3-1-2", "0-3-5,8-3-1,11-2-6,1-2-6", "5-1-6,10-5-2,1-5-3,12-5-3" ]
changes_quadruple = [ "0-3-5,2-3-7,9-5-7,10-3-2", "3-3-7,8-3-7,3-1-2,0-3-5,5-1-6", "6-2-6,1-2-1,8-3-6,3-3-6,0-4-1"  ]
changes_quintuple = [ "8-4-2,12-4-3,5-4-5,0-4-1,3-1-7,11-3-7", "6-2-6,12-5-2,2-3-4,11-2-5,0-3-5", "3-3-5,8-3-5,10-5-2,1-5-4,0-4-1,11-2-4" ]


changes_quadruple_bis = [ "3-3-4,8-3-5,6-4-5,6-2-6", "1-5-4,10-5-4,0-3-5,4-6-5,7-6-5"  ]
changes_quintuple_bis = [ "2-3-4,10-5-1,1-5-1,12-5-2,3-1-7,11-1-7,6-2-6", "3-1-6,11-1-6,5-1-6,0-3-5,10-3-4,8-3-6" ]

$EXPS << GetExp(defaults, initCaOption, changes_quintuple, "mixed-quintuple", 5, topo, links, demands, 1, extraProperties, "setAp")
$EXPS << GetExp(defaults, initCaOption, changes_quadruple, "mixed-quadruple", 4, topo, links, demands, 1, extraProperties, "setAp")
$EXPS << GetExp(defaults, initCaOption, changes_triple, "mixed-triple", 3, topo, links, demands, 1, extraProperties, "setAp")
$EXPS << GetExp(defaults, initCaOption, changes_double, "mixed-double", 2, topo, links, demands, 1, extraProperties, "setAp")
$EXPS << GetExp(defaults, initCaOption, changes_single, "mixed-single", 1, topo, links, demands, 1, extraProperties, "setAp")
$EXPS << GetExp(defaults, initCaOption, changes_quadruple_bis, "mixed-quadruple-bis", 4, topo, links, demands, 1, extraProperties, "setAp")
$EXPS << GetExp(defaults, initCaOption, changes_quintuple_bis, "mixed-quintuple-bis", 5, topo, links, demands, 1, extraProperties, "setAp")



changes_0.each do |ch|
  GetExps(defaults, initCaOption,  ch["values"], ch["description"], "topos/topoOrbit4" , "topos/links_topoOrbit4", demands, 1, extraProperties, "setAp").each do |exp|
      #  $EXPS << exp
  end
end



$protocols_def=["UDP", "TCP"]
$invalidations_def = ["no", "yes"]
$profiles_def = ["hysteresis", "standard" ]
$repetitions_def = 1

