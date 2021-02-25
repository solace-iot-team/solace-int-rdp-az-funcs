#!/usr/bin/env bash

scriptDir=$(cd $(dirname "$0") && pwd);
scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
if [ -z "$SOLACE_INTEGRATION_PROJECT_HOME" ]; then echo ">>> ERROR: - $scriptName - missing env var: SOLACE_INTEGRATION_PROJECT_HOME"; exit 1; fi
source $SOLACE_INTEGRATION_PROJECT_HOME/.lib/functions.sh

############################################################################################################################
# Environment Variables

  if [ -z "$LOG_DIR" ]; then export LOG_DIR="$SOLACE_INTEGRATION_PROJECT_HOME/logs"; mkdir -p $LOG_DIR; fi
  if [ -z "$WORKING_DIR" ]; then export WORKING_DIR="$SOLACE_INTEGRATION_PROJECT_HOME/tmp"; mkdir -p $WORKING_DIR; fi

############################################################################################################################
# Settings

  outputDir="$WORKING_DIR/solace-broker"; mkdir -p $outputDir;
  # rm -rf $outputDir/*;
  brokerInventoryFile="$outputDir/broker.inventory.yml"
  export ANSIBLE_PYTHON_INTERPRETER=$(python3 -c "import sys; print(sys.executable)")
  export ANSIBLE_VERBOSITY=3
  export ANSIBLE_SOLACE_ENABLE_LOGGING=True
  if [ -z "$ANSIBLE_SOLACE_LOG_PATH" ]; then export ANSIBLE_SOLACE_LOG_PATH="$LOG_DIR/solace-broker/$scriptName.ansible-solace.log"; fi

  integrationSettingsFile=$(assertFile $scriptName "$WORKING_DIR/integration.settings.json") || exit

############################################################################################################################
# Run

  echo ">>> run test ..."
    playbook=$(assertFile $scriptName "$scriptDir/run-test.playbook.yml") || exit
    brokerInventoryFile=$(assertFile $scriptName "$brokerInventoryFile") || exit
    ansible-playbook \
      -i $brokerInventoryFile \
      $playbook \
       --extra-vars "SOLACE_INTEGRATION_PROJECT_HOME=$SOLACE_INTEGRATION_PROJECT_HOME" \
       --extra-vars "LOG_DIR=$LOG_DIR" \
       --extra-vars "WORKING_DIR=$outputDir" \
       --extra-vars "INTEGRATION_SETTINGS_FILE=$integrationSettingsFile"
    code=$?; if [[ $code != 0 ]]; then echo ">>> ERROR - $code"; exit 1; fi
  echo ">>> success."
