

def GetSimpleExps(defaults, qdiscs, description, bottleneckRates, rates, topo, demands, repetitions, extraProperties, protocols, info, max_duration)

    exps = Array.new
    
    qdiscs.each  {|qdisc|
        bottleneckRates.each {|bottleneckRate|
            rates.each {|rate|
                protocols.each { |protocol|
                    demands.each   { |demand|
                        (1..repetitions).each { |repetition|
                            exp = { "value" => defaults, "demand" => demand,  "qdisc" => qdisc, "topo" => topo,  "repetition" => repetition, "extraProperties" => extraProperties, "info" => info, "olsrdebuglevel" => 4, "max_duration" => max_duration, "bottleneckRate" =>  bottleneckRate, "rate" => rate, "protocol" => protocol}
                            exps << exp unless bottleneckRate>rate
                        }
                    }
                }
            }
        }
    }
        
    
    return exps
end
    
$EXPS = Array.new



protocols=["UDP","TCP"]

repetitions = 1
topo="topology.xml"
#demands="0.05,0.05,0.05,0.05,0.05,0.05"
demands=[0.1,2,5,10]
extraProperties=""
        #"--setAp 00:11:22:33:44:55"
defaults="omf-5.4 exec TestBufferbloat.rb --  --stabilizeDelay 2 --channels 1,6,11"
info=""
qdiscs=["fq_codel"]
description="Bb exps"
bottleneckRates=[1,2,5,11]
rates=[1,2,5,11]
max_duration=14

exps=GetSimpleExps(defaults, qdiscs, description, bottleneckRates, rates, topo, demands, repetitions, extraProperties, protocols, info, max_duration)

exps.each{ |exp|
        $EXPS << exp
}


