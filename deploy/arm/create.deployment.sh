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

    settingsFile="$scriptDir/settings.json"
    settings=$(cat $settingsFile | jq .)
      projectName=$( echo $settings | jq -r '.projectName' )


echo
echo "##########################################################################################"
echo "# Deploy Project to Azure"
echo "# Project Name   : '$projectName'"
echo "# Settings:"
echo $settings | jq

if [ -z "$autoRun" ]; then
  echo; read -n 1 -p "- Press key to continue, CTRL-C to exit ..." x; echo; echo
fi

runScript="$scriptDir/common.create.sh $autoRun"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi
  cd $scriptDir

runScript="$scriptDir/rdp2blob.create.sh $autoRun"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi
  cd $scriptDir

###
# The End.
