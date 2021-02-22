#!/usr/bin/env bash

scriptDir=$(cd $(dirname "$0") && pwd);
scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));

############################################################################################################################
# Environment Variables

  if [ -z "$SOLACE_INTEGRATION_AZURE_PROJECT_NAME" ]; then echo ">>> ERROR: - $scriptName - missing env var: SOLACE_INTEGRATION_AZURE_PROJECT_NAME"; exit 1; fi
  if [ -z "$SOLACE_INTEGRATION_AZURE_LOCATION" ]; then echo ">>> ERROR: - $scriptName - missing env var: SOLACE_INTEGRATION_AZURE_LOCATION"; exit 1; fi

  if [ -z "$WORKING_DIR" ]; then export WORKING_DIR="$SOLACE_INTEGRATION_PROJECT_HOME/tmp"; mkdir -p $WORKING_DIR; fi
  if [ -z "$LOG_DIR" ]; then export LOG_DIR="$WORKING_DIR/logs"; mkdir -p $LOG_DIR; fi

  if [ -z "$RUN_FG" ]; then export RUN_FG="false"; fi


############################################################################################################################
# Prepare

  mkdir -p $LOG_DIR; rm -rf $LOG_DIR/*
  mkdir -p $WORKING_DIR; rm -rf $WORKING_DIR/*

############################################################################################################################
# Scripts

testScripts=(
  # "azure/delete.az.resources.sh"
  "azure/create.az.blob-storage.sh"
  "generate.local.settings.sh"
  "azure/create.az.function-resources.sh"
  "release/build.release-packages.sh"
  "azure/deploy.az.functions.sh"
  "generate.integration.settings.sh"
  # "npm integration-tests"
  # "azure/delete.az.resources.sh"
)

############################################################################################################################
# Run

  FAILED=0

  # for testing
  # RUN_FG="true"

  for testScript in ${testScripts[@]}; do
    if [ "$FAILED" -eq 0 ]; then
      runScript="$scriptDir/$testScript"
      if [[ "$RUN_FG" == "false" ]]; then
        logFile="$LOG_DIR/$testScript.out"; mkdir -p "$(dirname "$logFile")";
        $runScript > $logFile 2>&1
      else
        $runScript
      fi
      code=$?; if [[ $code != 0 ]]; then echo ">>> ERROR - code=$code - runScript='$runScript' - $scriptName"; FAILED=1; fi
    fi
  done


##############################################################################################################################
# Check for errors

filePattern="$LOG_DIR"
errors=$(grep -n -r -e "ERROR" $filePattern )

if [[ -z "$errors" && "$FAILED" -eq 0 ]]; then
  echo ">>> FINISHED:SUCCESS - $scriptName"
  touch "$LOG_DIR/$scriptName.SUCCESS.out"
else
  echo ">>> FINISHED:FAILED";
  if [ ! -z "$errors" ]; then
    while IFS= read line; do
      echo $line >> "$LOG_DIR/$scriptName.ERROR.out"
    done < <(printf '%s\n' "$errors")
  fi
  exit 1
fi

###
# The End.