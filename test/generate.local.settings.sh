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

  secretsBlobStorageFile=$(assertFile $scriptName "$WORKING_DIR/azure/secrets.blob-storage.json") || exit
  templateLocalSettingsFile=$(assertFile $scriptName "$SOLACE_INTEGRATION_PROJECT_HOME/template.local.settings.json") || exit
  localSettingsFile="$SOLACE_INTEGRATION_PROJECT_HOME/local.settings.json"

############################################################################################################################
# Run
echo " >>> Creating local.settings.json ..."

  # fixed
  export Rdp2BlobStorageContainerName="solacerdptest"
  export Rdp2BlobStoragePathPrefix="fixed/prefix"

  secretsBlobStorage=$(cat $secretsBlobStorageFile | jq .)
  export bloblConnectionString=$(echo $secretsBlobStorage | jq -r '.connectionString')
  localSettings=$(cat $templateLocalSettingsFile | jq .)

  localSettings=$(echo $localSettings | jq ".Values.Rdp2BlobStorageConnectionString=env.bloblConnectionString")
  localSettings=$(echo $localSettings | jq ".Values.Rdp2BlobStorageContainerName=env.Rdp2BlobStorageContainerName")
  localSettings=$(echo $localSettings | jq ".Values.Rdp2BlobStoragePathPrefix=env.Rdp2BlobStoragePathPrefix")

  echo $localSettings | jq . > $localSettingsFile
  cat $localSettingsFile | jq .

echo " >>> Success."


###
# The End.
