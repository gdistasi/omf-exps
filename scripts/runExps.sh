#!/bin/bash

#Run multiple experiments

#hour (in 0-23) when our reserve slot time ends
if ! [[ $ENDTIME ]]; then
  echo "Warnig: ENDTIME (lasthour:lastminute) is not set."
fi

#EXPS="Layer25:FCPRA:UDP:1-2:NOAP:NOTCPDUMP Layer25:MVCRA:UDP:1-2:NOAP:NOTCPDUMP Layer25:NONE:UDP:1-2:NOAP:NOTCPDUMP \
#      Layer25:FCPRA:TCP:1-2:NOAP:NOTCPDUMP Layer25:MVCRA:TCP:1-2:NOAP:NOTCPDUMP Layer25:NONE:TCP:1-2:NOAP:NOTCPDUMP \
#      Olsrd:MVCRA:UDP:1-2:SETAP:RUNTCPDUMP  Olsrd:FCPRA:UDP:1-2:SETAP:RUNTCPDUMP Olsrd:NONE:UDP:1-2:SETAP:RUNTCPDUMP \
#      Olsrd:MVCRA:TCP:1-2:SETAP:RUNTCPDUMP  Olsrd:FCPRA:TCP:1-2:SETAP:RUNTCPDUMP Olsrd:NONE:TCP:1-2:SETAP:RUNTCPDUMP \
#      Layer25:MVCRA:UDP:1-2:SETAP:RUNTCPDUMP  Layer25:FCPRA:UDP:1-2:SETAP:RUNTCPDUMP Layer25:NONE:UDP:1-2:SETAP:RUNTCPDUMP \
#      Olsrd:MVCRA:TCP:3-6:SETAP:RUNTCPDUMP  Olsrd:FCPRA:TCP:3-6:SETAP:RUNTCPDUMP Olsrd:NONE:TCP:3-6:SETAP:RUNTCPDUMP"
#EXPS="Olsrd:MVCRA:UDP:1-2:SETAP:RUNTCPDUMP Olsrd:MVCRA:TCP:1-2:SETAP:RUNTCPDUMP  Olsrd:FCPRA:UDP:1-2:SETAP:RUNTCPDUMP Olsrd:FCPRA:TCP:1-2:SETAP:RUNTCPDUMP Olsrd:NONE:UDP:1-2:SETAP:RUNTCPDUMP "


WHICH_NUMCHANGES="3"
#time for nodes to reboot
REBOOT_TIME=100

RUNEXP=`dirname $0`/run.sh

if [[ $ENDTIME ]]; then
  ENDHOUR=`echo $ENDTIME | cut -d ":" -f 1`
  LASTMINUTE=`echo $ENDTIME | cut -d ":" -f 2`


 if [ $((LASTMINUTE-5)) -lt 0 ]; then
   ENDHOUR=$((ENDHOUR-1))
   if [ $ENDHOUR -lt 0 ]; then
      ENDHOUR=23
   fi
   LASTMINUTE=59
 fi

fi

#security check; if our time is finished, quit.
function check_time(){
  
    local hour=`date +"%k"`
    local minute=`date +"%M"`
    
    if [ $hour -eq $ENDHOUR ] && [ $minute -gt $((LASTMINUTE-5)) ]; then
      
      echo "Slot ended. Quit."
      
      #kill connection to orbit
      killall ruby
      sleep 5
      killall -9 ruby
      sleep 5
      killall sshd
      exit 0

    fi

}

function clean(){
  rm -f /tmp/*.log 2>/dev/null
}

numExp=0

if [[ $EXTRAINFO ]]; then
  EXTRANAME="-$EXTRAINFO"
fi

if ! [[ $EXP_SCRIPT ]]; then
  export EXP_SCRIPT="main.rb"
fi


#script starts here
for EXP in $EXPS; do
  STACK=`echo $EXP | cut -d ":" -f 1`
  ALGO=`echo $EXP | cut -d ":" -f 2`
  PROTOCOL=`echo $EXP | cut -d ":" -f 3`
  NUMREPS=`echo $EXP | cut -d ":" -f 4`
  SETAP=`echo $EXP | cut -d ":" -f 5`
  RUNTCPDUMP=`echo $EXP | cut -d ":" -f 6`
  
  if [[ $AGG_OPTIONS ]]; then
    
    AGG_ON=`echo $AGG_OPTIONS | cut -d ":" -f 1`
    AGG_DELAY=`echo $AGG_OPTIONS | cut -d ":" -f 2`
    AGG_AWARE=`echo $AGG_OPTIONS | cut -d ":" -f 3`
    AGG_ALGO=`echo $AGG_OPTIONS | cut -d ":" -f 4`
    
    EXTRAOPT=" --aggregation $AGG_ON --aggregationDelay $AGG_DELAY --aggregationAware $AGG_AWARE --aggregationAwareAlgorithm $AGG_ALGO "
    
    
  fi
  
  
  if [[ $ALGO == "MVCRA" ]]; then
     NUMCHANGES_t=$WHICH_NUMCHANGES
  else
     NUMCHANGES_t="0"
  fi
  
  for NUMCHANGES in $NUMCHANGES_t; do
  
    from=`echo $NUMREPS | cut -d "-" -f 1`
    to=`echo $NUMREPS | cut -d "-" -f 2`
    i=$from
    
    while [ $i -le $to ]; do
	
  
	LOGDIR="test-$EXP_SCRIPT-$STACK-$ALGO-$NUMCHANGES-$PROTOCOL-$SETAP-${RUNTCPDUMP}$EXTRANAME"
	
	if [[ $AGG_OPTIONS ]]; then
	    LOGDIR="$LOGDIR-AGG-$AGG_ON-$AGG_DELAY-$AGG_AWARE-$AGG_ALGO"
	fi
	
	LOGDIR="$LOGDIR-rep$i"

	export ALGO
	export NUMCHANGES
	export PROTOCOL
	export STACK
	#EXTRAOPT=""
	if [[ $SETAP == "SETAP" ]]; then
	  EXTRAOPT=" $EXTAOPT --setAp 11:11:11:11:11:11 "
	fi
	if [[ $RUNTCPDUMP == "RUNTCPDUMP" ]]; then
	  EXTRAOPT=" $EXTRAOPT --startTcpdump yes "
	fi
	export EXTRAOPT
	
	
	echo "Press CTRL+C to stop now, before the next experiment ($LOGDIR)..."
	sleep 4
	
	if ! [[ $EXPSCRIPT ]] || [  $EXPSCRIPT = "normal" ]; then
	  
	  $RUNEXP | tee -i exp.log
	
	elif [ $EXPSCRIPT = "simple" ]; then
	
	  ./runSimple.sh | tee -i exp.log
	
	else
	    echo 'Error. EXPSCRIPT must be set to "normal" or "simple".'
	    exit 1
	fi
	
	echo "Press CTRL+C to stop now (after the experiment $LOGDIR)..."
	sleep 4

	#get the logs
	`dirname $0`/get_results.sh $LOGDIR; sleep 20

	mv exp.log $LOGDIR; #mv /tmp/*log $LOGDIR
	
	#copy the logs on my node and remove the log dir
	(scp -r $LOGDIR orbit@143.225.229.142:exps/ >> err-exps-log 2>&1 && rm -rf $LOGDIR && ssh orbit@143.225.229.142 "touch exps/$LOGDIR/finished" ) & 
  
	if [ $ENV != "NEPTUNE" ]; then
	  #del logs on nodes and reboot nodes
	  `dirname $0`/reboot.sh
  
	  sleep $REBOOT_TIME
	#./del-logs.sh; sleep 15; ifconfig wlan0 down; ifconfig wlan1 down; rmmod ath5k;
	fi
	
	if [[ $ENDTIME ]]; then
	  echo "Checking time to see if I have to stop..."
	  check_time
	fi
	
	clean
	
	i=$((i+1))
	
	numExp=$((numExp+1))
	
	if [ $numExp == 4 ]; then
	  sleep 100;
	  numExp=0;
	fi
	
	done
   done
done

