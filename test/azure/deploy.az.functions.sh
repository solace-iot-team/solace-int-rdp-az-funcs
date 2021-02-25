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
# Settings

  srcDir="$SOLACE_INTEGRATION_PROJECT_HOME"
  outputDir="$WORKING_DIR/azure"; mkdir -p $outputDir;
  releasePackagesDir="$WORKING_DIR/release-packages"

  packageVersion=$(node -p -e "require('$srcDir/package.json').version")
  if [[ $? != 0 ]]; then echo ">>> ERROR: get package version via node binary"; exit 1; fi

  resourceGroupName="$SOLACE_INTEGRATION_AZURE_PROJECT_NAME-rg"
  functionAppName="$SOLACE_INTEGRATION_AZURE_PROJECT_NAME"

  functions=(
    "solace-rdp-2-blob"
  )

############################################################################################################################
# Run
echo " >>> Deploying function ..."

  echo " >>> retrieving function app info ..."
    outputFunctionAppShowFile="$outputDir/function.$functionAppName.info.json"
    az functionapp show \
      --name $functionAppName \
      --resource-group $resourceGroupName \
      --verbose \
      > $outputFunctionAppShowFile
    if [[ $? != 0 ]]; then echo " >>> ERROR: retrieving function info: $functionAppName"; exit 1; fi
    cat $outputFunctionAppShowFile | jq .
  echo " >>> success."

  for function in ${functions[@]}; do

    zipDeployFile=$(assertFile $scriptName "$releasePackagesDir/$function.v$packageVersion/$function.v$packageVersion.zip") || exit
    echo " >>> deploying function zip file: $zipDeployFile ..."
    echo "     sleeping for 2m"; sleep 2m;
      outputFunctionAppDeploymentSourceConfigZipFile="$outputDir/function.$functionAppName.$function.zip-deploy.json"
      az functionapp deployment source config-zip \
          --resource-group $resourceGroupName \
          --name $functionAppName \
          --src $zipDeployFile \
          --timeout 300 \
          --verbose \
          > $outputFunctionAppDeploymentSourceConfigZipFile
      if [[ $? != 0 ]]; then echo " >>> ERROR: deploying function zip file: $zipDeployFile"; exit 1; fi
      cat $outputFunctionAppDeploymentSourceConfigZipFile | jq .
    echo " >>> success."

    echo " >>> retrieving function secrets ..."
      code=1; tries=0
      while [[ $code -gt 0 && $tries -lt 20 ]]; do
        ((tries++))
        functionAppInfo=$(cat $outputFunctionAppShowFile | jq .)
        appId=$(echo $functionAppInfo | jq -r '.id')
        outputFunctionSecretsFile="$outputDir/function.$functionAppName.$function.secrets.json"
        az rest \
          --method post \
          --uri "$appId/functions/$function/listKeys?api-version=2018-11-01" \
          --verbose \
          > $outputFunctionSecretsFile
        code=$?
        if [[ $code != 0 ]]; then
          echo "code=$code && tries=$tries, sleep 1m"
          sleep 1m;
        fi
      done
      if [[ $code != 0 ]]; then echo " >>> ERROR: retrieving function secrets: $functionAppName.$function"; exit 1; fi
      cat $outputFunctionSecretsFile | jq .
    echo " >>> success."
  done
echo " >>> Success."


###
# The End.
