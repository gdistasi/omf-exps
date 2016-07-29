#!/bin/bash
SSH="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q"

for i in `cat topo53 | tr , " "`; do ($SSH root@$i "rm -f /var/log/caserver.log /var/log/mesh.log /var/log/caagent.log /tmp/ditg-rec-log /tmp/tcpdump* /tmp/olsrd.log; \
                          /etc/init.d/omf-resctl-5.3 stop; rm  /var/log/omf-resctl-5.3.log; /sbin/reboot";)&  done
                          wait
                          echo "Done."

