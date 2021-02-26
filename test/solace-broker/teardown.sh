#!/usr/bin/env bash

scriptDir=$(cd $(dirname "$0") && pwd);
scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
if [ -z "$SOLACE_INTEGRATION_PROJECT_HOME" ]; then echo ">>> ERROR: - $scriptName - missing env var: SOLACE_INTEGRATION_PROJECT_HOME"; exit 1; fi
source $SOLACE_INTEGRATION_PROJECT_HOME/.lib/functions.sh

############################################################################################################################
# Environment Variables

  if [ -z "$WORKING_DIR" ]; then export WORKING_DIR="$SOLACE_INTEGRATION_PROJECT_HOME/tmp"; mkdir -p $WORKING_DIR; fi
  if [ -z "$LOG_DIR" ]; then export LOG_DIR="$WORKING_DIR/logs"; mkdir -p $LOG_DIR; fi

############################################################################################################################
# Settings

  outputDir="$WORKING_DIR/solace-broker"; mkdir -p $outputDir;
  brokerInventoryFile="$outputDir/broker.inventory.yml"
  export ANSIBLE_PYTHON_INTERPRETER=$(python3 -c "import sys; print(sys.executable)")
  export ANSIBLE_VERBOSITY=3
  export ANSIBLE_SOLACE_ENABLE_LOGGING=True
  if [ -z "$ANSIBLE_SOLACE_LOG_PATH" ]; then export ANSIBLE_SOLACE_LOG_PATH="$LOG_DIR/solace-broker/$scriptName.ansible-solace.log"; fi

############################################################################################################################
# Run

  echo ">>> teardown broker service ..."
    playbook=$(assertFile $scriptName "$scriptDir/teardown-broker.playbook.yml") || exit
    ansible-playbook \
      $playbook \
       --extra-vars "BROKER_INVENTORY_FILE=$brokerInventoryFile"
    code=$?; if [[ $code != 0 ]]; then echo ">>> ERROR - $code"; exit 1; fi
  echo ">>> success."
