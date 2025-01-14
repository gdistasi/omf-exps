# To sync

ifconfig eth0:1 192.168.8.2
ip route add default via 192.168.8.200

#pass:
#fantasmadicante

mkdir l2routing
rsync -rL giovanni@143.225.229.142:l2routing/orbit l2routing

#crea file con lista nodi
#omf-5.3  exec create_topo_files.rb -- --topo topos/topoOrbit0Neptune --env NEPTUNE

cd l2routing/orbit

ENV=NEPTUNE ./prepare.sh topos/topo5NodesNeptune 

#per aggiornare i driver lato client
./scripts/update-omfagent.sh

#riavvia gli OMF RC
./scripts/restart-resctl.sh

# Channel assignment simple - DONE

 #Orbit
omf-5.3 exec channelChange.rb -- --protocol TCP --env ORBIT --topo topos/topo2Nodes --links topos/links_topo2Nodes --demands 0.5 --initialDemands 0.5 --stack Olsrd --stabilizeDelay 120

 #Neptune
 omf-5.3 exec channelChange.rb -- --protocol TCP --env NEPTUNE --topo topos/topo2NodesNeptune --links topos/links_topo2Nodes --demands 0.5 --initialDemands 0.5 --stack Olsrd --stabilizeDelay 120


# Channel assignment - TODO

 #Orbit
ifconfig eth0:1 192.168.8.2
ip route add default via 192.168.8.200

ENDTIME="14:00" EXPS=" Olsrd:FCPRA:TCP:1-1:DONOTSEPAP:NORUNTCPDUMP Olsrd:MVCRA:TCP:1-1:DONOTSEPAP:NORUNTCPDUMP  " ENV="ORBIT" TOPO_FILE="topos/topoOrbit0" LINKS_FILE="topos/links_topoOrbit0" ./scripts/runExps.sh


 #Neptune

ENDTIME="14:00" EXPS=" Olsrd:FCPRA:TCP:1-1:DONOTSEPAP:NORUNTCPDUMP Olsrd:MVCRA:TCP:1-1:DONOTSEPAP:NORUNTCPDUMP " ENV="NEPTUNE" TOPO_FILE="topos/topoOrbit0Neptune" LINKS_FILE="topos/links_topoOrbit0" ./scripts/runExps.sh


5 nodes TOPOLOGY


ENDTIME="14:00" EXPS=" Olsrd:FCPRA:TCP:1-1:DONOTSEPAP:NORUNTCPDUMP Olsrd:MVCRA:TCP:1-1:DONOTSEPAP:NORUNTCPDUMP  " ENV="ORBIT" TOPO_FILE="topos/topoOrbit0" LINKS_FILE="topos/links_topoOrbit0" ./scripts/runExps.sh


 #Neptune

ENDTIME="14:00" EXPS=" Olsrd:FCPRA:TCP:1-1:DONOTSEPAP:NORUNTCPDUMP " ENV="NEPTUNE" TOPO_FILE="topos/topo5NodesNeptune" LINKS_FILE="topos/links_topo5NodesNeptune" ./scripts/runExps.sh





Per i risultati:
scripts/get_results.sh directory

Per il grafico:
scripts/getGraph.sh directory

