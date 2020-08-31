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
    outputDir="./deployment"
    outputFile="deploy-output.json"

echo
echo "##########################################################################################"
echo "# Deploy to Azure"
echo "# Project Name   : '$projectName'"
echo "# Location       : '$azLocation'"
echo "# Template       : '$templateFile'"
echo "# Parameters     : '$parametersFile'"
echo

#####################################################################################
# Prepare Dirs
mkdir $outputDir > /dev/null 2>&1
rm -rf $outputDir/*

#####################################################################################
# Resource Group
echo " >>> Creating Resource Group ..."
az group create \
  --name $projectName \
  --location "$azLocation" \
  --tags projectName=$projectName \
  --verbose
if [[ $? != 0 ]]; then echo " >>> ERR: creating resource group"; exit 1; fi
echo " >>> Success."

#####################################################################################
# Run ARM Template
echo " >>> Creating Resources ..."
az deployment group create \
  --name $projectName"_Deployment" \
  --resource-group $projectName \
  --template-file $templateFile \
  --parameters $parametersFile \
  --verbose \
  > "$outputDir/$outputFile"

if [[ $? != 0 ]]; then echo " >>> ERR: creating resources."; exit 1; fi
echo " >>> Success."

echo; echo; echo;
echo "TODO: Now the function specific stuff"

# Create function specific resources:
# rdp 2 blob:
# the blob
# the config params for the function
# // "STORAGE_CONNECTION_STRING": "DefaultEndpointsProtocol=https;AccountName=skdldatalake;AccountKey=HozXgZYrL2w6thu7f/B6mkMhfwWxKnBWMdBlaiOS1bCwM239l5OLKPi220vzfj+K5KylMCxLqi+UOVKTcHWv3Q==;EndpointSuffix=core.windows.net",
# // "STORAGE_CONTAINER_NAME": "solacerdptest",
# // "STORAGE_PATH_PREFIX": "solace-rdp-2-blob"
#
# Then: actually deploy the zip file


exit


echo "##########################################################################################"
echo "# Output dir  : $outputDir"
echo "# Output files:"
cd $outputDir
ls -la *.json
echo
echo
###
# The End.
