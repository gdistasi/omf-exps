OMFVER=5.4

if [[ $1 ]]; then
 ssh root@$1 "/etc/init.d/omf-resctl-${OMFVER} stop; sleep 2; killall -9 ruby1.8; sleep 3; /etc/init.d/omf-resctl-${OMFVER} start; "
else

for i in `cat topo53 | tr , " "`; do ssh root@$i "/etc/init.d/omf-resctl-${OMFVER} stop; sleep 1; killall -9 ruby1.8; sleep 3; /etc/init.d/omf-resctl-${OMFVER} start; " &  done
fi
