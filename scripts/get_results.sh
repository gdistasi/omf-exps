#!/bin/bash

OMFVER=5.4

#set the needed environment variable
. orbit-var.sh
. exp-var.sh  2> /dev/null

if ! [[ $ENV ]]; then
  ENV="ORBIT"
fi

# check in any case if the variables have been set
if [[ ! $GATEWAYS ]] || ! [[ $NODES ]]; then
	echo "Set GATEWAYS, CASERVER and NODES env variables"
	exit 1
fi

logdir=$1

mkdir $logdir 

for i in `echo $GATEWAYS | tr "," " "` ; do
  scp root@$i:/tmp/ditg.log* $logdir/  2>/dev/null
  #scp root@$i:/tmp/itgrecLog.txt $logdir/itgrecLog.txt-$i
done
for i in `echo $GATEWAYS | tr "," " "` ; do
   scp root@$i:/tmp/tmp/itgsend.log $logdir/itgsend.log-$i 2>/dev/null
done

#if [[ $BIFLOW == "yes" ]]; then
  for i in `echo $AGGREGATORS | tr "," " "` ; do
    scp root@$i:/tmp/ditg.log* $logdir/ 
    #scp root@$i:/tmp/itgrecLog.txt $logdir/itgrecLog.txt-$i
  done
  for i in `echo $GATEWAYS | tr "," " "` ; do
    scp root@$i:/tmp/tmp/itgsend.log $logdir/itgsend.log-$i
  done
#fi

for i in `echo $NODES | tr "," " "`; do 
    echo "Copying files from node $i"
    (mkdir -p $logdir/$i;
    scp -v root@$i:"/var/log/caagent.log /var/log/mesh.log /var/log/omf-resctl-${OMFVER}.log /tmp/rtLog* /tmp/tcpdump-* /var/log/syslog  /tmp/itgmanager.log" $logdir/$i 2>/dev/null;
    find $logdir/$i/ -iname "*.pcap" -exec mv \{\} $logdir/ \; 
    #mv $logdir/$i/olsrd-2.conf $logdir/$i/olsrd.conf 2>/dev/null
    ssh root@$i dmesg > $logdir/$i/dmesg 2>&1 ;
    
    #other files
    if [[ $FILES ]]; then
      scp -v root@$i:"$FILES" $logdir/$i/ 2> /dev/null;
    fi
    )&
    
    #virtualmesh
    #scp root@$i:"/root/iwconnect.out /var/log/aodvd.log /var/log/aodvd.rtlog /var/log/aodvd.replog" $logdir/$i/ 2>/dev/null;)&
        
done

wait

sleep 2

scp root@$CASERVER:/var/log/caserver.log $logdir/ 2>/dev/null

#copy the omf ec log
#if [ -e /tmp/$2.log ]; then
#  cp /tmp/$2.log $logdir
#else
#  echo "OMF EC log file not copied."
#fi

if [ -e stats-layer25.txt ]; then
  mv stats-layer25.txt $logdir 
fi

if ls $logdir/*pcap >/dev/null 2>&1; then
    gzip $logdir/*pcap
fi

if [[ $EXPID ]]; then
  cp run.sh $logdir
  cp /tmp/$EXPID* $logdir && rm /tmp/$EXPID*
fi


if [[ "ORBIT" == $ENV ]]; then
  USER="gdistasi"
else  
  USER="root"
fi
 
find /tmp/ -maxdepth 1 -iname "default*" -uid `id $USER | ruby -nae 'puts $F[0].split("=")[1].split("(")[0]'` -exec mv \{\} $logdir \;
      
#zipping pcap and .log files
find $logdir -iname \*.pcap -exec gzip {} \; &
find $logdir -iname \*.log -exec gzip {} \; &

touch $logdir/orbit

who > $logdir/who 2>&1
ps afxu > $logdir/processes 2>&1

for i in $LOGFILES; do

  node=`echo $i | cut -d ":" -f 1`
  files=`echo $i | cut -d ":" -f 2 | tr "," " "`
  scp root@$node:"$files" $logdir/$node/;
  
done

#echo "Deleting logs on nodes."
#./del-logs.sh

