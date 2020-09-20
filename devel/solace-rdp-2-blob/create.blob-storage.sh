#!/bin/bash
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
# All rights reserved.
# Licensed under the MIT License.

clear
scriptDir=$(cd $(dirname "$0") && pwd);
source $scriptDir/../.lib/functions.sh; if [[ $? != 0 ]]; then echo " >>> ERR: sourcing functions.sh."; exit 1; fi


#####################################################################################
# settings
#
    settingsFile=$(assertFile "$scriptDir/../settings.json") || exit
    deploymentDir="$scriptDir/../deployment"
    createAzRgFile=$(assertFile "$deploymentDir/create.az-rg.json") || exit

#####################################################################################
# read settings from file
#
settings=$(cat $settingsFile | jq .)
projectName=$( echo $settings | jq -r '.projectName' )
solaceRdp2BlobSettings=$( echo $settings | jq -r '."solace-rdp-2-blob"')

createAzRgJSON=$(cat $createAzRgFile | jq .)
resourceGroupName=$( echo $createAzRgJSON | jq -r '.name' )
azLocation=$( echo $createAzRgJSON | jq -r '.location' )

echo
echo "##########################################################################################"
echo "# Create Blob Storage (data lake)"
echo "# Resource Group : '$resourceGroupName'"
echo "# Location       : '$azLocation'"
echo "# Settings       :"
echo $solaceRdp2BlobSettings | jq

#####################################################################################
# Prepare Dirs
mkdir $deploymentDir > /dev/null 2>&1

#####################################################################################
# Blob Storage
echo " >>> Creating Blob Storage ..."
dataLakeAccountName=$( echo $solaceRdp2BlobSettings | jq -r '.dataLakeAccountName')
sku=$( echo $solaceRdp2BlobSettings | jq -r '.sku')
az storage account create \
  --name $dataLakeAccountName \
  --resource-group $resourceGroupName \
  --location $azLocation \
  --sku $sku \
  --enable-hierarchical-namespace "true" \
  --tags projectName=$projectName \
  --verbose \
  > $deploymentDir/create.blob-storage.json
if [[ $? != 0 ]]; then echo " >>> ERR: creating resource group"; exit 1; fi
echo " >>> Success."
echo
echo " Next: copy the Connection String ..."
echo
###
# The End.
