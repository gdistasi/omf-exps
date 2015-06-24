for i in 1 2 3 4; do ssh root@node$i "remountrw; rm /*gz; /etc/init.d/omf-resctl-5.3 restart"; done;
