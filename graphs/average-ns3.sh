#!/bin/bash

# Decode the files of different experiments putting them in the same .txt file
# For each experiment, all the DITG logs decoded and then the decoded logs are summed up.
# Create as output a log file with a column for each experiment.
# Accept as parameters the directories which contain the DITG logs (log filenames must start with ditg.log)

EXTRACT=`dirname $0`/extract.rb
CALC=`dirname $0`/calc.rb
MERGE=`dirname $0`/merge.rb
ITGPLOT=`dirname $0`/ITGplot

rm -f output*
rm -f *-averaged.txt

ind=0

exps=""
numExps=0

if [ $WHAT == "" ]; then
  WHAT="Thr"
fi

function checkSize(){
   local file=$1
   
   local filesize=$(stat -c%s "$file")
 
   if [ $filesize -eq 0 ]; then
     echo "Warning: file $file has size 0."
   fi

}

for i in $*; do
   echo "$i"

   numExps=$((numExps+1))

   exp=`basename $i`
   exps="$exps $exp"

   # index for repetitions
   k=0   

   # for each experiment serie decode all 
   if  ls $i-rep* >/dev/null 2>&1; then
       reps=`ls $i-rep*`
   else
       reps=$i
   fi

   for d in $reps; do
        files=""

        ruby $EXTRACT $d/result $WHAT > output-$exp-$k

        #go to the next repetition
	k=$((k+1))

   done

   ruby $CALC --average output-$exp-* > $ind-averaged.txt

   rm output*
 
   ind=$((ind+1))

done

#create output files

#Octave File
ruby $MERGE *-averaged.txt > ResultOctave.txt

#ITGPlot file
echo "Time $exps Aggregate-Flow" > ResultItgplot.txt
ruby $CALC --sum *-averaged.txt > Sum.txt
ruby $MERGE *-averaged.txt Sum.txt >> ResultItgplot.txt

listExps=""
for p in `seq $numExps`; do
  listExps="$listExps$p"

  if [ $p -lt $numExps ]; then
      listExps="$listExps,"
  fi

done

$ITGPLOT ResultItgplot.txt [$listExps]


#clean
rm *-averaged.txt
rm Sum.txt


