#!/bin/bash

TESTBED=$1
ENV=$2
TOPO=$3
EXP=$4
END=$5

ssh gdistasi@$TESTBED "cd l2routing/orbit;  \
		       ./scripts/exit_at.sh $END; \
		       (./scripts/check.sh &) ; \
		       ENV=$ENV ./prepare.sh $TOPO; \
		       screen -d -m ruby $EXP "
		       
		       