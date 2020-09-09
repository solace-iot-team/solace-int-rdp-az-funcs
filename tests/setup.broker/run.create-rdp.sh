#!/bin/bash
# ---------------------------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
