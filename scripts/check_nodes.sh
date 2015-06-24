echo " "
for i in `cat topo53 | tr , " "`; do (ping -c 1 $i >/dev/null 2>&1; if [ $? != 0 ];  then echo "Node $i did not respond."; fi;)& done

