#!/bin/bash
# ---------------------------------------------------------------------------------------------
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
# All rights reserved.
# Licensed under the MIT License.
# ---------------------------------------------------------------------------------------------

autoRun=$1
if [ -z "$autoRun" ]; then clear; fi

echo; echo "##############################################################################################################"
echo "#"
echo "# Script: "$(basename $(test -L "$0" && readlink "$0" || echo "$0"));

##############################################################################################################################
# Settings

    scriptDir=$(cd $(dirname "$0") && pwd);
    source $scriptDir/.lib/run.project-env.sh
    if [[ $? != 0 ]]; then echo "ERR >>> aborting."; echo; exit 1; fi

    # logging & debug: ansible
    ansibleLogFile="$scriptDir/tmp/ansible.log"
    export ANSIBLE_LOG_PATH="$ansibleLogFile"
    export ANSIBLE_DEBUG=False
    export ANSIBLE_VERBOSITY=3
    # logging: ansible-solace
    export ANSIBLE_SOLACE_LOG_PATH="./tmp/ansible-solace.log"
    export ANSIBLE_SOLACE_ENABLE_LOGGING=True
  # END SELECT


x=$(showEnv)
if [ -z "$autoRun" ]; then
  x=$(wait4Key)
fi
##############################################################################################################################
# Prepare

mkdir $scriptDir/tmp > /dev/null 2>&1
mkdir $scriptDir/deployed > /dev/null 2>&1
rm -f $scriptDir/tmp/*.*

##############################################################################################################################
# Run

brokerInventory=$(assertFile "$scriptDir/broker.inventory.yml") || exit
playbook="$scriptDir/playbook.get.yml"

# --step --check -vvv
ansible-playbook \
                  -i $brokerInventory \
                  $playbook

if [[ $? != 0 ]]; then echo ">>> ERROR ..."; echo; exit 1; fi

echo; echo "##############################################################################################################"
echo; echo "deployed:"; echo;
ls -la $scriptDir/deployed/*
echo; echo "tmp:"
ls -la $scriptDir/tmp/*.*
echo; echo



###
# The End.
