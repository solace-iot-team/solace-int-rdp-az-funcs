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

scriptDir=$(cd $(dirname "$0") && pwd);
source $scriptDir/.lib/run.project-env.sh
if [[ $? != 0 ]]; then echo "ERR >>> aborting."; echo; exit 1; fi

##############################################################################################################################
# User chooses deployment or as parameter
if [ -z "$autoRun" ]; then
  rdpFunctionSettingsFile=$(chooseDeployment "./settings.*.yml")
  if [[ $? != 0 ]]; then echo "ERR >>> aborting."; echo; exit 1; fi
else
  rdpFunctionSettingsFile=$(assertFile "$autoRun") || exit
fi

echo "# Settings : $rdpFunctionSettingsFile"


##############################################################################################################################
# Settings
    scriptDir=$(cd $(dirname "$0") && pwd);
    # logging & debug: ansible
    ansibleLogFile="$scriptDir/tmp/ansible.log"
    export ANSIBLE_LOG_PATH="$ansibleLogFile"
    export ANSIBLE_DEBUG=False
    export ANSIBLE_VERBOSITY=3
    # logging: ansible-solace
    export ANSIBLE_SOLACE_LOG_PATH="$scriptDir/tmp/ansible-solace.log"
    export ANSIBLE_SOLACE_ENABLE_LOGGING=True

    x=$(showEnv)

    if [ -z "$autoRun" ]; then
      x=$(wait4Key)
    fi

##############################################################################################################################
# Prepare

mkdir $scriptDir/tmp > /dev/null 2>&1
mkdir $scriptDir/deployed > /dev/null 2>&1
rm -f $scriptDir/tmp/*.*
rm -f $scriptDir/deployed/*

##############################################################################################################################
# Run

brokerInventory=$(assertFile "$scriptDir/broker.inventory.yml") || exit
playbook="$scriptDir/playbook.create-rdp.yml"

# --step --check -vvv
ansible-playbook \
                  -i $brokerInventory \
                  $playbook \
                  --extra-vars "SETTINGS_FILE=$rdpFunctionSettingsFile"

if [[ $? != 0 ]]; then echo ">>> ERROR ..."; echo; exit 1; fi

##############################################################################################################################
# Copy Deployment Settings
#

cp $rdpFunctionSettingsFile "$scriptDir/deployed/settings.deployed.yml"
if [[ $? != 0 ]]; then echo ">>> ERROR ..."; echo; exit 1; fi

echo; echo "##############################################################################################################"
echo; echo "deployed:"; echo;
ls -la ./deployed/*
echo; echo "tmp:"
ls -la ./tmp/*.*
echo; echo



###
# The End.
