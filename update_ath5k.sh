for i in `cat topo53 | tr "," " "`; do 
    scp patches-omf-5.4/patchAgentCommands root@$i:
    scp patches-omf-5.4/ath5k.rb root@$i:/usr/share/omf-resctl-5.4/omf-resctl/omf_driver/ath5k.rb; 
    ssh root@$i "cd /usr/share/omf-resctl-5.4/omf-resctl/omf_agent/; patch < ~/patchAgentCommands"
done