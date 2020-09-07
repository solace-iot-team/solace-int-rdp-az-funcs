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

#####################################################################################
# settings
#
    scriptDir=$(cd $(dirname "$0") && pwd);
    settingsFile="$scriptDir/settings.json"
    deploymentDir="$scriptDir/deployment"


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
mkdir $deploymentDir > /dev/null 2>&1

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
