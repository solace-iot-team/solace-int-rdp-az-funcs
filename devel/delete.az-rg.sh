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
    source $scriptDir/.lib/functions.sh; if [[ $? != 0 ]]; then echo " >>> ERR: sourcing functions.sh."; exit 1; fi
    scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
    projectHome=${scriptDir%%/devel}
    deploymentDir="$projectHome/.deployment/devel"

    createAzRgFile=$(assertFile "$deploymentDir/create.az-rg.json") || exit

#####################################################################################
# read settings from file
#
createAzRgJSON=$(cat $createAzRgFile | jq .)
resourceGroupName=$( echo $createAzRgJSON | jq -r '.name' )

echo
echo "##########################################################################################"
echo "# Delete Azure Resource Group"
echo "# Resource Group : '$resourceGroupName'"
echo

#####################################################################################
# Prepare Dirs

#####################################################################################
# Resource Group
echo " >>> Deleting Resource Group ..."
  az group delete \
    --name $resourceGroupName \
    --verbose
if [[ $? != 0 ]]; then echo " >>> ERR: deleting resource group"; exit 1; fi
echo " >>> Success."

#####################################################################################
# Cleanup deployment
rm -rf $deploymentDir/*.json

echo "##########################################################################################"
echo "# Deployment dir: $deploymentDir"
echo "# Output files:"
cd $deploymentDir
ls -la *.json
echo
echo


###
# The End.
