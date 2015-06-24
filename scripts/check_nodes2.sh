echo " "
for i in `cat topo53 | tr , " "`; do ping -c 1 $i ; done

