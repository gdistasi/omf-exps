#!/bin/bash

# Decode the files of different experiments putting them in the same .txt file
# For each experiment, all the DITG logs decoded and then the decoded logs are summed up.
# Create as output a log file with a column for each experiment.
# Accept as parameters the directories which contain the DITG logs (log filenames must start with ditg.log)


samplingInterval=300

rm -f output*
rm -f *-averaged.txt

ind=0


function checkSize(){
   local file=$1
   
   local filesize=$(stat -c%s "$file")
 
   if [ $filesize -eq 0 ]; then
     echo "Warning: file $file has size 0."
   fi

}

for i in $*; do
   echo "$i"

   #index for repetitions
   k=0   

   #for each experiment serie decode all 
   for d in $i-rep*; do
   	numLog=0	
	files=""
   
	#sum over all the gateways
 	for j in $d/ditg.log*; do
	   checkSize $j
	   ITGDec $j -b $samplingInterval
	   mv bitrate.txt bitrate${numLog}.txt
	   files="$files bitrate${numLog}.txt"
   	   numLog=$((numLog+1))
   	done
        ruby calc.rb --sum --skipline $files > output-$i-$k
	rm $files

        #go to the next repetition
	k=$((k+1))

   done

   ruby calc.rb --average output-$i-* > $ind-averaged.txt
   rm output*
 
   ind=$((ind+1))
done

#create output files

#Octave File
ruby merge.rb *-averaged.txt > ResultOctave.txt

#ITGPlot file
echo "Time $* Aggregate-Flow" > ResultItgplot.txt
ruby calc.rb --sum *-averaged.txt > Sum.txt
ruby merge.rb *-averaged.txt Sum.txt >> ResultItgplot.txt


#clean
rm *-averaged.txt
rm Sum.txt


