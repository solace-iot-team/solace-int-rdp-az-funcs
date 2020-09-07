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

clear
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
