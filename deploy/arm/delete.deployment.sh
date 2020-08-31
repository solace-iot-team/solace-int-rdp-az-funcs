#!/bin/bash

clear

#####################################################################################
# settings
#
    scriptDir=$(pwd)

    settingsFile="$scriptDir/settings.json"
    settings=$(cat $settingsFile | jq .)
      projectName=$( echo $settings | jq -r '.projectName' )
      resourceGroup=$projectName

echo
echo "##########################################################################################"
echo "# Delete Project from Azure"
echo "# Project Name   : '$projectName'"
echo

echo " >>> Deleting Resource Group ..."
az group delete \
  --name $resourceGroup \
  --verbose
if [[ $? != 0 ]]; then echo " >>> ERR: deleting resource group"; exit 1; fi
echo " >>> Success."


###
# The End.
