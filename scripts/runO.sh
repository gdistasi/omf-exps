
#set NUMCHANGES, PROTOCOL and ALGO
#aodvRepOn yes=Fuurex no=uu

PROTOCOL="UDP"
if [[ ! $ENV ]]; then
  echo "Set ENV."
  exit 1
fi

if [ $ENV == "ORBIT" ]; then
  TOPO="topos/topoOrbitMyxen"
  LINKFILE="topos/links_topoOrbitMyxen"
#  DEMANDS="1.5,2,1.5,2.5"
  DEMANDS="1.5"
else
  TOPO="topos/topoMyxen"
  LINKFILE="topos/links_topoMyxen"
  DEMANDS="0.005"
fi


omf-5.3 exec aodv-exp.rb --  --stack Aodv \
                         --topo $TOPO --links $LINKFILE \
	                 --duration 300 \
			 --demands ${DEMANDS} \
                         --protocol $PROTOCOL  \
                         --extradelay 40 --stabilizeDelay 60 \
                         --env ${ENV} \
			 --startTcpdump no \
                         --reputationEnabled yes --maliciousNode no \
                         --setAp 11:11:11:11:11:11
