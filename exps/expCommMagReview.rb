require 'scripts/getExps.rb'

defaults="omf-5.4 exec main.rb -- --stack Olsrd --extraDelay 60 --algo MA --stabilizeDelay 120 --channels 36,48,149,157,165,44,161 --arpFilter yes"

info="review-arpFiltered"

$EXPS = Array.new


exps_old = [ {"topo" => "topos/topoSimpleLuciaEndHosts", "links" => "topos/links_topoSimpleLuciaEndHosts", "id" => "3", "value" => "#{defaults} --demands 0.1 --caOption \"0-1-2,S\"  --initialAlgo MA --initialAlgoOption \"0-0-4,1-0-2,S\" ", "repetitions" => 1, "info" => info , "extraProperties" => "--setAp 00:11:22:33:44:55", "olsrdebuglevel" => 5,   "protocols" => ["UDP,TCP"], "profiles" =>  ["standard","hysteresis"] },

{"topo" => "topos/topoSimpleLuciaEndHosts", "links" => "topos/links_topoSimpleLuciaEndHosts", "id" => "1", "value" => "#{defaults}  --demands 0.1  --caOption \"0-1-2,1-1-2,S\" --initialAlgo MA --initialAlgoOption \"0-0-4,1-0-5,S\" ", "repetitions" => 1, "protocols" => ["UDP,TCP"], "profiles" =>  ["standard","hysteresis"], "info" => info, "extraProperties" => "--setAp 00:11:22:33:44:55", "olsrdebuglevel" => 5 },
           
]

exps_old.each do  |exp|
   # $EXPS << exp
end


initCaOption="0-0-3,0-1-4,1-0-2,1-1-5,2-0-3,2-1-5,3-0-1,3-1-3,4-0-1,4-1-6,5-0-1,5-1-4,6-0-2,6-1-4,7-0-2,7-1-6,8-0-3,8-1-4,9-0-5,9-1-6,10-0-3,10-1-5,11-0-1,11-1-2,12-0-4,12-1-5"
topo="topos/topoOrbit4"
links="topos/links_topoOrbit4"
#demands="0.05,0.05,0.05,0.05,0.05,0.05"
demands="0.07,0.07,0.07,0.07,0.07,0.07"
extraProperties="--setAp 00:11:22:33:44:55"


#changes_0=[ { "values" => [ "0-4-1", "10-3-1", "2-5-6", "3-3-4", "5-1-6" ], "description" => "complex1" } ]
#changes_1=[ { "values" => [ "3-1-2", "0-4-1", "5-4-5", "6-2-6", "12-4-3"  ], "description" => "complex2" } ]
#changes_2=[ { "values" => [ "5-1-6", "11-2-5", "3-3-4", "10-3-4", "2-5-6" ], "description" => "complex3" } ]
#changes_3=[ { "values" => [ "10-3-4", "6-2-6", "5-1-6", "9-6-1", "3-3-4"  ], "description" => "complex_4" } ]
# [ changes_0, changes_1, changes_2, changes_3 ].each do |ch|
 #$EXPS << GetComplexExpAllInOne(defaults, initCaOption,  ch, ch["description"], topo, links, demands, 1, extraProperties, "setAp")
#end


$protocols_def=["UDP,TCP"]
$profiles_def = [ "standard" ]
$repetitions_def = Integer(ENV['REPETITIONS'])
$invalidations_def = ["yes"]


changes_single = [ "5-1-6", "10-3-4", "4-6-2", "8-4-2", "11-2-5" ] #OK
changes_double = [ "4-6-2,9-6-1", "10-5-2,5-1-6", "0-4-1,10-3-1", "3-3-4,2-5-6", "11-2-5,0-4-1" ] #OK
changes_triple = [ "0-3-5,8-3-1,5-1-6", "5-1-6,10-5-2,1-5-4", "10-5-2,1-5-4,3-3-4", "12-4-3,0-4-1,8-4-2", "2-5-6,11-2-5,5-1-6"  ]
changes_quadruple = [ "0-3-5,2-3-4,5-1-6,3-3-4", "3-1-2,5-1-6,0-4-6,10-5-4", "2-5-6,11-2-5,3-3-4,6-2-6", "10-5-2,1-5-4,8-4-2,5-1-6", "12-4-3,5-4-5,0-4-1,4-6-2"  ]
changes_quintuple = [ "11-2-5,6-2-6,12-4-1,8-4-5,6-4-3" , "8-4-2,12-4-3,5-4-5,0-4-1,7-6-1", "6-2-6,12-5-2,2-3-4,11-2-5,0-3-5", "10-5-2,1-5-4,0-4-1,2-5-6,8-3-1", "5-1-6,3-1-2,10-5-2,2-5-6,10-3-4" ]

#$EXPS << GetExp(defaults, initCaOption, changes_single, "new-fixed", 1, topo, links, demands, $repetitions_def, extraProperties, info)
#$EXPS << GetExp(defaults, initCaOption, changes_double, "new-fixed", 2, topo, links, demands, $repetitions_def, extraProperties, info)
#$EXPS << GetExp(defaults, initCaOption, changes_triple, "new-fixed", 3, topo, links, demands, $repetitions_def, extraProperties, info)
$EXPS << GetExp(defaults, initCaOption, changes_quintuple, "new-fixed", 5, topo, links, demands, $repetitions_def, extraProperties, info)
#$EXPS << GetExp(defaults, initCaOption, changes_quadruple, "new-fixed", 4, topo, links, demands, $repetitions_def, extraProperties, info)

[ changes_single, changes_double, changes_triple, changes_quadruple, changes_quintuple ].each do |cc|
    
   # GetSimpleExps(defaults, initCaOption, cc, "new-single", cc[0].split(",").size, topo, links, demands, 1, extraProperties, "setAp").each do |e|
	#$EXPS << e
   # end
  
end



