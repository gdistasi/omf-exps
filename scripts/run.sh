
#set NUMCHANGES, PROTOCOL and ALGO


if [[ ! $ENV ]]; then
   echo "Set ENV to either ORBIT, XEN or NEPTUNE"
   exit 1
fi

if [[ ! $TOPO_FILE ]]; then
   echo "Set TOPO_FILE"
   exit 1
fi

if [[ ! $LINKS_FILE ]]; then
   echo "Set LINKS_FILE"
   exit 1
fi

if [ $ALGO == "NONE" ]; then
    ALGO="FCPRA"
    EXTRAOPT="$EXTRAOPT --dontassign yes "
  
fi

if [ $STACK == "OlsrdFast" ]; then
    STACK="Olsrd"
    EXTRAOPT="$EXTRAOPT --profile fast "
fi

if [ $STACK == "OlsrdMod" ]; then
    STACK="Olsrd"
    EXTRAOPT="$EXTRAOPT --switchOff true "
fi


if [ $STACK == "OlsrdModFast" ]; then
    STACK="Olsrd"
    EXTRAOPT="$EXTRAOPT --profile fast --switchOff true "
fi


echo "Running: omf-5.3 exec $EXP_SCRIPT --  --stack $STACK \
                         --topo $TOPO_FILE --links $LINKS_FILE \
			 --duration 120 --algo $ALGO \
                         --initialDemands 1.5,2,1.5,2.5 \
                         --demands 0.1,0.06,0.06,0.05  \
                         --maxNumChannelChanges $NUMCHANGES \
                         --protocol $PROTOCOL  \
                         --extradelay 40 \
                         --stabilizeDelay 120  \ $EXTRAOPT \
                         --olsrdebug 2 --env $ENV"

omf-5.3 exec $EXP_SCRIPT --  --stack $STACK \
                         --topo $TOPO_FILE --links $LINKS_FILE \
			 --duration 120 --algo $ALGO \
                         --initialDemands 1.5,2,1.5,2.5 \
                         --demands 0.1,0.06,0.06,0.05  \
                         --maxNumChannelChanges $NUMCHANGES \
                         --protocol $PROTOCOL  \
                         --extradelay 40 \
                         $EXTRAOPT \
                         --olsrdebug 2 --env $ENV
                         

