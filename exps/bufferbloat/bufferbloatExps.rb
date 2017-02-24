

def GetSimpleExps(defaults, qdiscs, description, bottleneckRates, rates, topo, demands, repetitions, extraProperties, protocols, info, max_duration)

    exps = Array.new
    
    qdiscs.each  {|qdisc|
        bottleneckRates.each {|bottleneckRate|
            rates.each {|rate|
                protocols.each { |protocol|
                    demands.each   { |demand|
                        (1..repetitions).each { |repetition|
                            exp = {  "demands" => demand,  "qdisc" => qdisc, "topo" => topo,  "repetition" => repetition, "info" => info, "olsrdebuglevel" => 4, "max_duration" => max_duration, "bottleneckRate" =>  bottleneckRate, "rate" => rate, "protocol" => protocol, "defaults" => defaults}
                            exps << exp unless (bottleneckRate>rate or demand<bottleneckRate)
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
topo="bufferbloat/topology.xml"
#demands="0.05,0.05,0.05,0.05,0.05,0.05"
demands=[100,1000,5000,10000,24000,54000]
extraProperties=""
        #"--setAp 00:11:22:33:44:55"
defaults="--stabilizeDelay 2 --channels 1,6,11"
info="bufferbloat_0"
qdiscs=["fq_codel"]
description="Bb exps"
bottleneckRates=[1000,2000,5000,11000,24000,54000]
rates=[1000,2000,5000,11000,24000,54000]
max_duration=14

exps=GetSimpleExps(defaults, qdiscs, description, bottleneckRates, rates, topo, demands, repetitions, extraProperties, protocols, info, max_duration)

exps.each{ |exp|
        $EXPS << exp
}


