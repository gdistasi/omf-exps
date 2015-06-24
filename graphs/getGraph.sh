#!/bin/bash

# Decode the files of different experiments putting them in the same .txt file
# For each experiment, all the DITG logs decoded and then the decoded logs are summed up.
# Create as output a log file with a column for each experiment.
# Accept as parameters the directories which contain the DITG logs (log filenames must start with ditg.log)


samplingInterval=1000


for WHAT in "thr"; do

k=0

for i in $*; do
   numLog=0
   files=""
   for j in $i/ditg.log*; do
	   if [ $WHAT = "thr" ]; then
             ITGDec $j -b $samplingInterval
	     mv bitrate.txt bitrate${numLog}.txt
	     files="$files bitrate${numLog}.txt"
	   elif [ $WHAT = "loss" ]; then
   	     ITGDec $j -p $samplingInterval
	     mv packetloss.txt loss${numLog}.txt
	     files="$files loss${numLog}.txt"
	   elif [ $WHAT = "delay" ]; then
	     ITGDec $j -d $samplingInterval
	     mv delay.txt delay${numLog}.txt
	     files="$files delay${numLog}.txt"
	   fi

	   numLog=$((numLog+1))
   done
   k=$((k+1))
   if [ $WHAT = "thr" ] || [ $WHAT = "loss" ]; then
     ruby calc.rb --sum  --skipline $files > output$k
   elif [ $WHAT = "delay" ]; then
     ruby calc.rb --average  --skipline $files > output$k
   fi
done

ruby merge.rb output* > Result.txt

echo "Time $1 Aggregate-Flow" > ResultItgplot.txt
ruby calc.rb --sum output* > Sum.txt
ruby merge.rb output* Sum.txt >> ResultItgplot.txt
./ITGplot ResultItgplot.txt [1]

mkdir -p graphs

if [ $WHAT = "thr" ]; then
  cp ResultItgplot.eps $i/throughput.eps
  cp ResultItgplot.eps graphs/$i-throughput.eps
  mv ResultItgplot.txt $i/throughput.txt
elif [ $WHAT = "loss" ]; then
  cp ResultItgplot.eps $i/packetloss.eps
  cp ResultItgplot.eps graphs/$i-packetloss.eps                                           
  mv ResultItgplot.txt $i/packetloss.txt
elif [ $WHAT = "delay" ]; then
  cp ResultItgplot.eps $i/delay.eps
  cp ResultItgplot.eps graphs/$i-delay.eps                                           
  mv ResultItgplot.txt $i/delay.txt
fi

done


rm -f output*
rm -f bitrate*.txt
rm -f packetloss*.txt
