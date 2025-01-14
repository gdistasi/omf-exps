


5 nodes TOPOLOGY


ENDTIME="14:00" EXPS=" Olsrd:FCPRA:TCP:1-1:DONOTSEPAP:NORUNTCPDUMP Olsrd:MVCRA:TCP:1-1:DONOTSEPAP:NORUNTCPDUMP  " ENV="ORBIT" TOPO_FILE="topos/topoOrbit0" LINKS_FILE="topos/links_topoOrbit0" ./scripts/runExps.sh


 #Neptune

ENDTIME="00:00" EXPS=" Layer25:FCPRA:TCP:1-1:DONOTSEPAP:NORUNTCPDUMP " ENV="NEPTUNE" EXP_SCRIPT="mainAgg.rb" EXTRAOPT="--aggregation_enabled 1 --aggregation_delay 1000 --aggregation_algo AA-L2R" TOPO_FILE="topos/topo5NodesNeptune" LINKS_FILE="topos/links_topo5NodesNeptune" ./scripts/runExps.sh

omf-5.3 exec main.rb -- --topo topos/topo5NodesNeptune --links topos/links_topo5NodesNeptune --duration 300 --algo FCPRA --demands 0.5 --maxNumChannelChanges 3 --extradelay 10 --stabilizeDelay 120 --env NEPTUNE --stack Layer25 --aggregation_enabled 1 --aggregation_delay 1000


omf-5.3 exec main.rb -- --topo topos/topoOrbit1 --links topos/links_topoOrbit0 --duration 120 --algo FCPRA --demands 0.5,0.5,0.5,0.5,0.5,0.5 --maxNumChannelChanges 3 --extradelay 10 --stabilizeDelay 120 --env ORBIT --stack Layer25 --aggregation_enabled 1 --aggregation_delay 1000000

omf-5.3 exec mainAgg.rb -- --topo topos/topoOrbit1 --links topos/links_topoOrbit0 --duration 120 --algo FCPRA --demands 0.5,0.5,0.5,0.5,0.5,0.5 --maxNumChannelChanges 3 --extradelay 10 --stabilizeDelay 120 --env ORBIT --stack Layer25 --aggregation_enabled 1 --aggregation_delay 1000000