#!/usr/bin/env bash
scriptDir=$(cd $(dirname "$0") && pwd);
scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
if [ -z "$SOLACE_INTEGRATION_PROJECT_HOME" ]; then echo ">>> ERROR: - $scriptName - missing env var: SOLACE_INTEGRATION_PROJECT_HOME"; exit 1; fi
source $SOLACE_INTEGRATION_PROJECT_HOME/.lib/functions.sh

############################################################################################################################
# Environment Variables

  if [ -z "$LOG_DIR" ]; then export LOG_DIR="$SOLACE_INTEGRATION_PROJECT_HOME/logs"; mkdir -p $LOG_DIR; fi
  if [ -z "$WORKING_DIR" ]; then export WORKING_DIR="$SOLACE_INTEGRATION_PROJECT_HOME/tmp"; mkdir -p $WORKING_DIR; fi

  if [ -z "$SOLACE_INTEGRATION_AZURE_PROJECT_NAME" ]; then echo ">>> ERROR: - $scriptName - missing env var: SOLACE_INTEGRATION_AZURE_PROJECT_NAME"; exit 1; fi
  if [ -z "$SOLACE_INTEGRATION_AZURE_LOCATION" ]; then echo ">>> ERROR: - $scriptName - missing env var: SOLACE_INTEGRATION_AZURE_LOCATION"; exit 1; fi

############################################################################################################################
# Run

resourceGroupName="$SOLACE_INTEGRATION_AZURE_PROJECT_NAME-rg"

echo " >>> Check Resource Group ..."
  resp=$(az group exists --name $resourceGroupName)
echo " >>> Success."

if [ "$resp" == "false" ]; then echo " >>> INFO: resoure group does not exist"; exit; fi

echo " >>> Deleting Resource Group ..."
  az group delete \
      --name $resourceGroupName \
      --yes \
      --verbose
  if [[ $? != 0 ]]; then echo " >>> ERROR: deleting resource group"; exit 1; fi
echo " >>> Success."

echo  " >>> Clean working dir ..."
  rm -f "$WORKING_DIR/azure/*.json"

###
# The End.
