#!/bin/bash
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
# All rights reserved.
# Licensed under the MIT License.

SCRIPT_PATH=$(cd $(dirname "$0") && pwd);

##############################################################################################################################
# Settings

##############################################################################################################################
# Run

runScript="$SCRIPT_PATH/arm/.run.teardown.sh"; echo ">>> $runScript";
  $runScript; if [[ $? != 0 ]]; then echo ">>> ERR:$runScript"; echo; exit 1; fi

###
# The End.
