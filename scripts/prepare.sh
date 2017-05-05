#!/bin/bash

if [[ $1 == "" ]]; then
 echo "Usage: $0 topoFile"
 exit 1
fi

OMFVER=5.4

image_old="gdistasi-node-node7-10.grid.orbit-lab.org-2016-02-03-11-15-33.ndz"
image_411="gdistasi-node-node1-2.sb1.orbit-lab.org-2017-05-05-09-07-43.ndz"

image=$image_411

if  ! [[ $ENV ]]; then
    
    if [[ `hostname` == "console.grid.orbit-lab.org" ]]; then
      echo "Proceeding assuming ORBIT."
      export ENV="ORBIT"
    else
      echo "You must set ENV variable (to either ORBIT, NEPTUNE, ORBIT-SBx)."
      exit 1
    fi

fi


export RUBYLIB="/home/gdistasi/omf-tools/:/home/gdistasi/.gem/ruby/1.9.1/gems/nokogiri-1.6.7.1/lib/"
export PATH=$PATH:/home/gdistasi/.gem/ruby/1.9.1/bin


DIRA=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
omf-${OMFVER} exec ${DIRA}/create_topo_files.rb -- --topo $1 --env $ENV


if [[ $ENV == "ORBIT" ]] || [[ $ENV == ORBIT_SB* ]]; then

  omf-${OMFVER} tell -a offh -t system:topo:all

  sleep 60

  #image="gdistasi-node-node8-1.grid.orbit-lab.org-2015-10-29-09-50-20.ndz"

  #if [[ $DEBUG ]]; then
    #image="giovanni1-bis-debug.ndz"
    #image="gdistasi-node-node8-1.grid.orbit-lab.org-2015-09-24-06-47-16.ndz"
    #image="gdistasi-node-node4-18.grid.orbit-lab.org-2015-09-25-06-46-50.ndz"
    image="gdistasi-node-node7-10.grid.orbit-lab.org-2016-02-03-11-15-33.ndz"
    image_411="gdistasi-node-node1-2.sb1.orbit-lab.org-2017-05-05-09-07-43.ndz"
 # else
    #image="giovanni1-bis.ndz"
    #image="gdistasi-node-node10-12.grid.orbit-lab.org-2012-11-25-18-06-55.ndz" #omf-${OMFVER}-5.3
    #image="gdistasi-node-node5-17.grid.orbit-lab.org-2013-03-01-07-41-50.ndz"
    #image="gdistasi-node-node1-1.grid.orbit-lab.org-2013-03-02-07-31-52.ndz" #precise
    #image="gdistasi-node-node1-1.grid.orbit-lab.org-2013-03-02-08-48-25.ndz" #precise ath5k patched
    #image="gdistasi-node-node1-1.grid.orbit-lab.org-2013-03-05-06-55-13.ndz" #rule for getting to xmpp server
    #image="gdistasi-node-node1-1.grid.orbit-lab.org-2013-03-05-07-31-05.ndz" #aaaahhh ath5k update
    #image="gdistasi-node-node1-2.sb1.orbit-lab.org-2013-03-06-08-27-17.ndz" #ath5k really updated...
    #image="gdistasi-node-node1-1.sb1.orbit-lab.org-2013-03-06-10-32-16.ndz"
    #image="gdistasi-node-node1-2.sb1.orbit-lab.org-2013-03-07-08-15-39.ndz" #agentCommands patched
    #image="giovanni-new.ndz"
   #image="gdistasi-node-node4-18.grid.orbit-lab.org-2015-09-25-06-46-50.ndz"
      #  image="gdistasi-node-node4-18.grid.orbit-lab.org-2015-09-29-09-04-22.ndz"


  #fi
  


  #
 #omf-${OMFVER}-5.3 exec -s system:exp:imageNode -- --nodes `cat topo52` --image giovanni1-bis.ndz  --timeout 1200 --resetDelay 170 --resetTries  4
  omf-${OMFVER} load -t `cat topo53` -i $image  -o 900

  #giovanni3.ndz good - no patch for 20-7 - giovanni6.ndz new updated

  #giovanni1.ndz 2.6.35 (patch for 20-7) 
  #giovanni1-bis.ndz 3.0 updated
  #giovanni4.ndz 3.0

  #omf-${OMFVER}-5.2 load `cat topo52` giovanni2.ndz

  #omf-${OMFVER}-5.3 tell -a offh -t `cat topo53`

  sleep 30

  while omf-${OMFVER} tell -a on -t `cat topo53` | grep ServiceException; do
    sleep 10
  done

fi

sleep 80
./scripts/reboot.sh
sleep 120
#./install-madwifitools.sh

#./update_na.sh

#./scripts/restart-resctl.sh

#./scripts/update-omf-${OMFVER}agent.sh

#./scripts/restart-resctl.sh


