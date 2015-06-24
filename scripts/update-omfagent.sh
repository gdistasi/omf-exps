
cd patches
for i in `cat ../topo53 | tr , " "`; do scp agentCommands.rb nodeAgent.rb root@$i:/usr/share/omf-resctl-5.3/omf-resctl/omf_agent/;  \
                                     scp ath5k.rb virtualmesh.rb root@$i:/usr/share/omf-resctl-5.3/omf-resctl/omf_driver/; scp ~/iw root@$i:/usr/sbin/; \
                                  done

ssh root@node16-19 "apt-get install libcolamd2.7.1"

cd ..

./scripts/runall "cd /usr/lib; ln -s libpcap.so.1.1.1 libpcap.so.1"

