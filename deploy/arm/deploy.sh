#!/bin/bash

clear

#####################################################################################
# settings
#
    scriptDir=$(pwd)
    settingsFile="$scriptDir/settings.json"
    projectName=$( cat $settingsFile | jq -r '.projectName' )
    if [[ $? != 0 ]]; then echo " >>> ERR: reading projectName from $settingsFile"; exit 1; fi
    azLocation=$( cat $settingsFile | jq -r '.azLocation' )
    if [[ $? != 0 ]]; then echo " >>> ERR: reading azLocation from $settingsFile"; exit 1; fi
    templateFile="create.template.json"
    parametersFile="parameters.json"

echo
echo "##########################################################################################"
echo "# Deploy to Azure"
echo "# Project Name   : '$projectName'"
echo "# Location       : '$azLocation'"
echo "# Template       : '$templateFile'"
echo "# Parameters     : '$parametersFile'"
echo

echo " >>> Creating Resource Group ..."
az group create \
  --name $projectName \
  --location "$azLocation" \
  --verbose
if [[ $? != 0 ]]; then echo " >>> ERR: creating resource group"; exit 1; fi
echo " >>> Success."

echo " >>> Creating Resources ..."
az deployment group create \
  --name $projectName"_Deployment" \
  --resource-group $projectName \
  --template-file $templateFile \
  --parameters $parametersFile \
  --verbose
if [[ $? != 0 ]]; then echo " >>> ERR: creating resources."; exit 1; fi
echo " >>> Success."

###
# The End.
