#!/bin/bash

while /bin/true; do 
  if [ `who | grep -v gdistasi | wc -l` -gt 0 ]; then 
    killall ruby; sleep 3; killall -9 ruby; sleep 2; killall scp; killall bash; killall sshd; 
  fi  
done