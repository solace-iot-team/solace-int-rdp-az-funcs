#!/bin/bash
# ---------------------------------------------------------------------------------------------
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
# All rights reserved.
# Licensed under the MIT License.
# ---------------------------------------------------------------------------------------------

##############################################################################################################################
# Settings

  scriptDir=$(cd $(dirname "$0") && pwd);
  scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
  projectHome=${scriptDir%%/mtests/*}
  deploymentDir="$projectHome/.deployment/mtests"

  source ./.lib/functions.sh

  settingsTemplateFile=$(assertFile "$scriptDir/.template.settings.az-func.json") || exit
  settingsFile="$scriptDir/.settings.az-func.json"
  funcAppInfoFile=$(assertFile "$deploymentDir/rdp2blob.func-app-info.output.json") || exit

##############################################################################################################################
# Run

runScript="$scriptDir/stop.local.broker.sh auto"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

runScript="$scriptDir/start.local.broker.sh auto"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

# download certificate
certName="BaltimoreCyberTrustRoot.crt.pem"
curl -L "https://cacerts.digicert.com/$certName" > $scriptDir/$certName
if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi
# create settings file
funcAppInfoJSON=$(cat $funcAppInfoFile | jq)
settingsJSON=$(cat $settingsTemplateFile | jq)
export rdp2Blob_azFuncCode=$( echo $funcAppInfoJSON | jq -r '.functions."solace-rdp-2-blob".code' )
settingsJSON=$(echo $settingsJSON | jq ".az_rdp_2_blob_func.az_func_code=env.rdp2Blob_azFuncCode")
export rdp2Blob_azFuncHost=$( echo $funcAppInfoJSON | jq -r '.defaultHostName' )
settingsJSON=$(echo $settingsJSON | jq ".az_rdp_2_blob_func.az_func_host=env.rdp2Blob_azFuncHost")
echo $settingsJSON > $settingsFile

runScript="$scriptDir/run.create-rdp.sh $settingsFile"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

runScript="$scriptDir/run.get.sh auto"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

###
# The End.
