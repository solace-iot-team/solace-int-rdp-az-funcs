#!/bin/bash
# ---------------------------------------------------------------------------------------------
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
# All rights reserved.
# Licensed under the MIT License.
# ---------------------------------------------------------------------------------------------

SCRIPT_PATH=$(cd $(dirname "$0") && pwd);
source "./.lib/functions.sh"

##############################################################################################################################
# Settings
  resultsDir="$SCRIPT_PATH/results"

#####################################################################################
# Prepare Dirs
mkdir $resultsDir > /dev/null 2>&1
rm -rf $resultsDir/*

##############################################################################################################################
# Run

runScript="$SCRIPT_PATH/../deploy/.run.test.sh"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

runScript="$SCRIPT_PATH/setup.broker/.run.test.sh"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

runScript="$SCRIPT_PATH/broker.post.event.sh"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

x=$(wait4Time)

# compare msgs sent & number of files written to blob
resultsOutputFile="$resultsDir/blob.count.json"
runScript="$SCRIPT_PATH/../deploy/arm/rdp2blob.count.sh $resultsOutputFile"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

##############################################################################################################################
# Teardown
runScript="$SCRIPT_PATH/setup.broker/.run.teardown.sh"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

runScript="$SCRIPT_PATH/../deploy/.run.teardown.sh"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

##############################################################################################################################
# Done
echo;
echo "##############################################################################################################"
echo "# Results:"
echo
resultFiles=$(ls $resultsDir)
for resultFile in $resultFiles; do
  cat "$resultsDir/$resultFile" | jq
done



###
# The End.
