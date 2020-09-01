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

autoRun=$1
if [ -z "$autoRun" ]; then clear; fi

#####################################################################################
# settings
#
    scriptDir=$(cd $(dirname "$0") && pwd);
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
