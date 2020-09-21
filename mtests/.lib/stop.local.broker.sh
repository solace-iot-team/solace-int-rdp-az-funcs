#!/bin/bash
# ---------------------------------------------------------------------------------------------
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
# All rights reserved.
# Licensed under the MIT License.
# ---------------------------------------------------------------------------------------------

export brokerDockerContainerName="pubSubStandardSingleNode"

echo; echo "##############################################################################################################"
echo "removing container: $brokerDockerContainerName"
echo

docker rm -f "$brokerDockerContainerName"

echo; echo "docker ps -a:"; echo

docker ps -a

echo; echo "Done."; echo

###
# The End.
