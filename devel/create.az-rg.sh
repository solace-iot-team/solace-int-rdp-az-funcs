#!/bin/bash
# ---------------------------------------------------------------------------------------------
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
# All rights reserved.
# Licensed under the MIT License.
# ---------------------------------------------------------------------------------------------

clear

#####################################################################################
# settings
#

    scriptDir=$(cd $(dirname "$0") && pwd);
    scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
    projectHome=${scriptDir%%/devel}
    deploymentDir="$projectHome/.deployment/devel"

    settingsFile="$scriptDir/settings.json"

#####################################################################################
# read settings from file
#
settings=$(cat $settingsFile | jq .)
projectName=$( echo $settings | jq -r '.projectName' )
resourceGroupName=$( echo $settings | jq -r '.resourceGroupName' )
azLocation=$( echo $settings | jq -r '.azLocation' )


echo
echo "##########################################################################################"
echo "# Create Azure Resource Group"
echo "# Project Name   : '$projectName'"
echo "# Resource Group : '$resourceGroupName'"
echo "# Location       : '$azLocation'"
echo

#####################################################################################
# Prepare Dirs

#####################################################################################
# Resource Group
echo " >>> Creating Resource Group ..."
az group create \
  --name $resourceGroupName \
  --location "$azLocation" \
  --tags projectName=$projectName \
  --verbose \
  > $deploymentDir/create.az-rg.json
if [[ $? != 0 ]]; then echo " >>> ERR: creating resource group"; exit 1; fi
echo " >>> Success."

echo "##########################################################################################"
echo "# Deployment dir: $deploymentDir"
echo "# Output files:"
cd $deploymentDir
ls -la *.json
echo
echo

###
# The End.
