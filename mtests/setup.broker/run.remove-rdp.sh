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

    # deployed rdp function settings
    rdpFunctionSettingsDeployedFile=$(assertFile "$scriptDir/deployed/settings.deployed.yml") || exit
    export AS_SAMPLES_RDP_FUNCTION_SETTINGS_FILE=$rdpFunctionSettingsDeployedFile

    # logging & debug: ansible
    ansibleLogFile="./tmp/ansible.log"
    export ANSIBLE_LOG_PATH="$ansibleLogFile"
    export ANSIBLE_DEBUG=False
    export ANSIBLE_VERBOSITY=3
    # logging: ansible-solace
    export ANSIBLE_SOLACE_LOG_PATH="./tmp/ansible-solace.log"
    export ANSIBLE_SOLACE_ENABLE_LOGGING=True

x=$(showEnv)
if [ -z "$autoRun" ]; then
  x=$(wait4Key)
fi
##############################################################################################################################
# Prepare

mkdir $scriptDir/tmp > /dev/null 2>&1
rm -f $scriptDir/tmp/*.*

##############################################################################################################################
# Run
# select inventory
brokerInventory=$(assertFile "$scriptDir/broker.inventory.yml") || exit
playbook="$scriptDir/playbook.remove-rdp.yml"

# --step --check -vvv
ansible-playbook \
                  -i $brokerInventory \
                  $playbook \
                  --extra-vars "SETTINGS_FILE=$AS_SAMPLES_RDP_FUNCTION_SETTINGS_FILE"

if [[ $? != 0 ]]; then echo ">>> ERROR ..."; echo; exit 1; fi

##############################################################################################################################
# Delete Deployment Settings
#
rm -f $scriptDir/deployed/*


echo; echo "##############################################################################################################"
echo; echo "deployed:"; echo;
ls -la $scriptDir/deployed/*
echo; echo "tmp:"
ls -la $scriptDir/tmp/*.*
echo; echo



###
# The End.