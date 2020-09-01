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

SCRIPT_PATH=$(cd $(dirname "$0") && pwd);
source ./.lib/functions.sh

##############################################################################################################################
# Settings

  settingsTemplateFile=$(assertFile "$SCRIPT_PATH/.template.settings.az-func.json") || exit
  settingsFile="$SCRIPT_PATH/.settings.az-func.json"
  funcAppInfoFile=$(assertFile "$SCRIPT_PATH/../../deploy/arm/deployment/rdp2blob.func-app-info.output.json") || exit

##############################################################################################################################
# Run

runScript="$SCRIPT_PATH/stop.local.broker.sh auto"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

runScript="$SCRIPT_PATH/start.local.broker.sh auto"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

# download certificate
certName="BaltimoreCyberTrustRoot.crt.pem"
curl -L "https://cacerts.digicert.com/$certName" > $SCRIPT_PATH/$certName
if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi
# create settings file
funcAppInfoJSON=$(cat $funcAppInfoFile | jq)
settingsJSON=$(cat $settingsTemplateFile | jq)
export rdp2Blob_azFuncCode=$( echo $funcAppInfoJSON | jq -r '.functions."solace-rdp-2-blob".code' )
settingsJSON=$(echo $settingsJSON | jq ".az_rdp_2_blob_func.az_func_code=env.rdp2Blob_azFuncCode")
export rdp2Blob_azFuncHost=$( echo $funcAppInfoJSON | jq -r '.defaultHostName' )
settingsJSON=$(echo $settingsJSON | jq ".az_rdp_2_blob_func.az_func_host=env.rdp2Blob_azFuncHost")
echo $settingsJSON > $settingsFile

runScript="$SCRIPT_PATH/run.create-rdp.sh $settingsFile"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi


###
# The End.