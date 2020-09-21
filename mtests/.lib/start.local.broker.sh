#!/bin/bash
# ---------------------------------------------------------------------------------------------
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
# All rights reserved.
# Licensed under the MIT License.
# ---------------------------------------------------------------------------------------------

SCRIPT_NAME=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
SCRIPT_PATH=$(cd $(dirname "$0") && pwd);

export brokerDockerContainerName="pubSubStandardSingleNode"
dockerComposeYmlFile="./.lib/PubSubStandard_singleNode.yml"
brokerDockerImageLatest="solace/solace-pubsub-standard:latest"
export brokerDockerImage=$brokerDockerImageLatest

echo; echo "##############################################################################################################"
echo "creating container: $brokerDockerContainerName"
echo "image: $brokerDockerImage"
echo

# remove container first
docker rm -f "$brokerDockerContainerName" > /dev/null 2>&1
if [ "$brokerDockerImage" == "$brokerDockerImageLatest" ]; then
  # make sure we are pulling the latest
  docker rmi -f $brokerDockerImageLatest > /dev/null 2>&1
fi

docker-compose -f $dockerComposeYmlFile up -d
if [[ $? != 0 ]]; then echo ">>> ERR: $SCRIPT_PATH/$SCRIPT_NAME. aborting."; echo; exit 1; fi

echo

docker ps -a

echo; echo "Done."; echo

###
# The End.
