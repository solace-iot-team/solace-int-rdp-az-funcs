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
    scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
    projectHome=${scriptDir%%/deploy/*}
    deploymentDir="$projectHome/.deployment"

    settingsFile="$scriptDir/settings.json"
    settings=$(cat $settingsFile | jq .)

        projectName=$( echo $settings | jq -r '.projectName' )
        azLocation=$( echo $settings | jq -r '.azLocation' )
        resourceGroup=$projectName

    templateFile="$scriptDir/common.create.template.json"
    parametersFile="$scriptDir/common.create.parameters.json"
    outputDir="$deploymentDir"
    outputFile="common.create.output.json"

echo
echo "##########################################################################################"
echo "# Create Common Resources"
echo "# Project Name   : '$projectName'"
echo "# Location       : '$azLocation'"
echo "# Template       : '$templateFile'"
echo "# Parameters     : '$parametersFile'"
echo

#####################################################################################
# Prepare Dirs
mkdir $outputDir > /dev/null 2>&1
rm -f $outputDir/*.json

#####################################################################################
# Resource Group
echo " >>> Creating Resource Group ..."
az group create \
  --name $resourceGroup \
  --location "$azLocation" \
  --tags projectName=$projectName \
  --verbose
if [[ $? != 0 ]]; then echo " >>> ERR: creating resource group"; exit 1; fi
echo " >>> Success."

#####################################################################################
# Run ARM Template
echo " >>> Creating Common Resources ..."
az deployment group create \
  --name $projectName"_Common_Deployment" \
  --resource-group $resourceGroup \
  --template-file $templateFile \
  --parameters projectName=$projectName \
  --parameters $parametersFile \
  --verbose \
  > "$outputDir/$outputFile"

if [[ $? != 0 ]]; then echo " >>> ERR: creating resources."; exit 1; fi
echo " >>> Success."

echo "##########################################################################################"
echo "# Output dir  : $outputDir"
echo "# Output files:"
cd $outputDir
ls -la *.json
echo
echo
###
# The End.
