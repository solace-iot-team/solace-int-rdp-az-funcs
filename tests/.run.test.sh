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
