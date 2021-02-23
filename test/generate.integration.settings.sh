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

  localSettingsFile=$(assertFile $scriptName "$SOLACE_INTEGRATION_PROJECT_HOME/local.settings.json") || exit
  templateSettingsFile=$(assertFile $scriptName "$SOLACE_INTEGRATION_PROJECT_HOME/test/template.integration.settings.json") || exit
  outSettingsFile="$WORKING_DIR/integration.settings.json"

  functionAppName="$SOLACE_INTEGRATION_AZURE_PROJECT_NAME"
  functions=(
    "solace-rdp-2-blob"
    # "another-function"
  )
  functionAppInfoFile=$(assertFile $scriptName "$WORKING_DIR/azure/function.$functionAppName.info.json") || exit

############################################################################################################################
# Run
echo " >>> Creating integration.settings.json ..."

  export functionAppHost=$(cat $functionAppInfoFile | jq -r '.defaultHostName')
  # read the local settings
  localSettings=$(cat $localSettingsFile | jq .)
  export connectionString=$(echo $localSettings | jq -r '.Values.Rdp2BlobStorageConnectionString')
  export containerName=$(echo $localSettings | jq -r '.Values.Rdp2BlobStorageContainerName')
  export pathPrefix=$(echo $localSettings | jq -r '.Values.Rdp2BlobStoragePathPrefix')

  for function in ${functions[@]}; do
    echo " function:$function ..."
    export function

    if [ "$function" == "solace-rdp-2-blob" ]; then
      secretsFile=$(assertFile $scriptName "$WORKING_DIR/azure/function.$functionAppName.$function.secrets.json") || exit
      export functionCode=$(cat $secretsFile | jq -r '.default')

      integrationSettings=$(cat $templateSettingsFile | jq .)
      integrationSettings=$(echo $integrationSettings | jq '."'$function'".azure.function.code=env.functionCode')
      integrationSettings=$(echo $integrationSettings | jq '."'$function'".azure.function.host=env.functionAppHost')
      integrationSettings=$(echo $integrationSettings | jq '."'$function'".azure.storage.connection_string=env.connectionString')
      integrationSettings=$(echo $integrationSettings | jq '."'$function'".azure.storage.container_name=env.containerName')
      integrationSettings=$(echo $integrationSettings | jq '."'$function'".azure.storage.path_prefix=env.pathPrefix')

      echo $integrationSettings | jq . > $outSettingsFile

    else
      echo " >>>ERROR: unknown function=$function"; exit 1;
    fi
  done

  cat $outSettingsFile | jq .

echo " >>> Success."


###
# The End.
