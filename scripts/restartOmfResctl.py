#!/usr/bin/python


from xml.dom import minidom
import os
import sys
import time


   
if __name__ == '__main__':
    topo=sys.argv[1]
    confDir=sys.argv[2]
    
    if topo==None:
        sys.exit("Specify the topology file.")
        
    if os.environ["ENV"]=="MININET":
        
        omfresctls=os.popen("ps afxu | grep omf-resctl | grep root").read()
        lines=omfresctls.split("\n")
        for line in lines:
            if line.split().__len__()  < 2:
                continue
            
            pid=line.split()[1]
            user=line.split()[0]
            
            if user=="mininet":
                continue
            
            os.system("sudo kill %s" %pid)
            time.sleep(1)
            os.system("sudo kill -9 %s 2>/dev/null" %pid)
            
        #os.system("sudo /etc/init.d/omf-aggmgr-5.4 restart")
    
    
    xmldoc = minidom.parse(topo)

    itemlist = xmldoc.getElementsByTagName('node')
    
    i=1
    for n in itemlist:
        name = n.attributes['name'].value
        ip = "10.0.0.%d" %i
        if os.environ["ENV"]=="ORBIT":
            os.system("ssh root@%s \"/etc/init.d/omf-resctl-5.4 stop; sleep 1; killall -9 ruby; sleep 3; /etc/init.d/omf-resctl-5.4 start\""%ip)
        elif os.environ["ENV"]=="MININET":
                    os.system("ssh root@%s \"cd %s; omf-resctl-5.4 -C omf-resctl-%s.yaml --log stdout > omf-resctl-%s.log & \"" %(ip,confDir,name,name))
        i+=1
                
            
    
