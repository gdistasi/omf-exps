#!/bin/bash

# Decode the files of different experiments putting them in the same .txt file
# For each experiment, all the DITG logs decoded and then the decoded logs are summed up.
# Create as output a log file with a column for each experiment.
# Accept as parameters the directories which contain the DITG logs (log filenames must start with ditg.log)

EXTRACT=`dirname $0`/extract.rb
CALC=`dirname $0`/calc.rb
MERGE=`dirname $0`/merge.rb
ITGPLOT=`dirname $0`/ITGplot

for WHAT in "thr"; do

k=0

for i in $*; do

   if [[ $WHAT == "thr" ]]; then
      ruby $EXTRACT $i/result Thr > output$k
   fi
   
   k=$((k+1))

done

ruby $MERGE output* > Result.txt

echo "Time $1 Aggregate-Flow" > ResultItgplot.txt
ruby $CALC --sum output* > Sum.txt
ruby $MERGE output* Sum.txt >> ResultItgplot.txt
$ITGPLOT ResultItgplot.txt [1]

mkdir -p graphs

if [ $WHAT = "thr" ]; then

  cp ResultItgplot.eps $i/throughput.eps
  cp ResultItgplot.eps graphs/$i-throughput.eps
  mv ResultItgplot.txt $i/throughput.txt

elif [ $WHAT = "loss" ]; then

  cp ResultItgplot.eps $i/packetloss.eps
  cp ResultItgplot.eps graphs/$i-packetloss.eps                                            mv ResultItgplot.txt $i/packetloss.txt

elif [ $WHAT = "delay" ]; then

  cp ResultItgplot.eps $i/delay.eps
  cp ResultItgplot.eps graphs/$i-delay.eps                                           
  mv ResultItgplot.txt $i/delay.txt

fi

done

#rm -f output*
rm -f bitrate*.txt
rm -f packetloss*.txt
