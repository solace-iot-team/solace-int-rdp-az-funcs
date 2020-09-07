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
scriptDir=$(cd $(dirname "$0") && pwd);
source $scriptDir/.lib/functions.sh; if [[ $? != 0 ]]; then echo " >>> ERR: sourcing functions.sh."; exit 1; fi

#####################################################################################
# settings
#
    deploymentDir="$scriptDir/deployment"
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

echo "##########################################################################################"
echo "# Deployment dir: $deploymentDir"
echo "# Output files:"
cd $deploymentDir
ls -la *.json
echo
echo

#####################################################################################
# Cleanup deployment
rm -rf $deploymentDir/*

###
# The End.
