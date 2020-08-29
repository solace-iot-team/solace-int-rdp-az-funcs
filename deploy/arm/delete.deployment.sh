#!/bin/bash

clear

#####################################################################################
# settings
#
    scriptDir=$(pwd)
    settingsFile="$scriptDir/settings.json"
    projectName=$( cat $settingsFile | jq -r '.projectName' )
    if [[ $? != 0 ]]; then echo " >>> ERR: reading projectName from $settingsFile"; exit 1; fi

echo
echo "##########################################################################################"
echo "# Delete Project from Azure"
echo "# Project Name   : '$projectName'"
echo

echo " >>> Deleting Resource Group ..."
az group delete \
  --name $projectName \
  --verbose
if [[ $? != 0 ]]; then echo " >>> ERR: deleting resource group"; exit 1; fi
echo " >>> Success."


###
# The End.
