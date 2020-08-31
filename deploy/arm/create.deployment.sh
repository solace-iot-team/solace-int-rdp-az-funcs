#!/bin/bash

clear

#####################################################################################
# settings
#
    scriptDir=$(pwd)

    settingsFile="$scriptDir/settings.json"
    settings=$(cat $settingsFile | jq .)
      projectName=$( echo $settings | jq -r '.projectName' )

echo
echo "##########################################################################################"
echo "# Deploy Project to Azure"
echo "# Project Name   : '$projectName'"
echo "# Settings:"
echo $settings | jq

echo; read -n 1 -p "- Press key to continue, CTRL-C to exit ..." x; echo; echo

source ./common.create.sh; cd $scriptDir
source ./rdp2blob.create.sh; cd $scriptDir

###
# The End.
