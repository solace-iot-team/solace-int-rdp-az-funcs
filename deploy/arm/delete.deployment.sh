#!/bin/bash
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
# All rights reserved.
# Licensed under the MIT License.

autoRun=$1
if [ -z "$autoRun" ]; then clear; fi

#####################################################################################
# settings
#
    scriptDir=$(cd $(dirname "$0") && pwd);
    deploymentDir="$scriptDir/deployment"
    settingsFile="$scriptDir/settings.json"
    settings=$(cat $settingsFile | jq .)
      projectName=$( echo $settings | jq -r '.projectName' )
      resourceGroup=$projectName

echo
echo "##########################################################################################"
echo "# Delete Project from Azure"
echo "# Project Name   : '$projectName'"
echo

yes=""
if [ ! -z "$autoRun" ]; then
  yes="--yes -y"
fi

echo " >>> Deleting Resource Group ..."
  az group delete \
    --name $resourceGroup \
    --verbose \
    $yes
  code=$?
  # echo "code=$code"
  if [ -z "$autoRun" ]; then
    if [[ $code != 0 ]]; then echo " >>> ERR: deleting resource group"; exit 1; fi
  fi
echo " >>> Success."

rm -f $deploymentDir/*

###
# The End.
