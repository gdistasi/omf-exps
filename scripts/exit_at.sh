#!/bin/bash

TIME=$1

echo "killall ruby; sleep 4; killall -9 ruby; rsync -r autoexps/test_* giovanni@143.225.229.142:/home/giovanni/Tests/; killall scp; killall sshd; killall screen" | at $TIME
