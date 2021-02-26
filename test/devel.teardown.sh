#!/usr/bin/env bash
scriptDir=$(cd $(dirname "$0") && pwd);
scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));

############################################################################################################################
# Environment Variables

  if [ -z "$SOLACE_INTEGRATION_PROJECT_HOME" ]; then echo ">>> ERROR: - $scriptName - missing env var: SOLACE_INTEGRATION_PROJECT_HOME"; exit 1; fi
  if [ -z "$SOLACE_INTEGRATION_AZURE_PROJECT_NAME" ]; then echo ">>> ERROR: - $scriptName - missing env var: SOLACE_INTEGRATION_AZURE_PROJECT_NAME"; exit 1; fi
  if [ -z "$SOLACE_INTEGRATION_AZURE_LOCATION" ]; then echo ">>> ERROR: - $scriptName - missing env var: SOLACE_INTEGRATION_AZURE_LOCATION"; exit 1; fi

  if [ -z "$WORKING_DIR" ]; then export WORKING_DIR="$SOLACE_INTEGRATION_PROJECT_HOME/tmp"; mkdir -p $WORKING_DIR; fi
  if [ -z "$LOG_DIR" ]; then export LOG_DIR="$WORKING_DIR/logs"; mkdir -p $LOG_DIR; fi

############################################################################################################################
# Prepare

  mkdir -p $LOG_DIR; rm -rf $LOG_DIR/*
  mkdir -p $WORKING_DIR;
  
############################################################################################################################
# Scripts

testScripts=(
  "solace-broker/teardown.sh"
  "azure/delete.az.resources.sh"
)

############################################################################################################################
# Run

  for testScript in ${testScripts[@]}; do
    runScript="$scriptDir/$testScript"
    echo "starting: $runScript ..."
    $runScript
    code=$?; if [[ $code != 0 ]]; then echo ">>> ERROR - code=$code - runScript='$runScript' - $scriptName"; exit 1; fi
    echo "success"
  done

###
# The End.
