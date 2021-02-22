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

  localSettingsFile=$(assertFile $scriptName "$SOLACE_INTEGRATION_PROJECT_HOME/local.settings.json")
  localSettings=$(cat $localSettingsFile | jq .)

############################################################################################################################
# Run

resourceGroupName="$SOLACE_INTEGRATION_AZURE_PROJECT_NAME-rg"
azLocation="$SOLACE_INTEGRATION_AZURE_LOCATION"
functionAppStorageAccountName="solacerdpfuncappstorage"
functionAppServicePlanName="$SOLACE_INTEGRATION_AZURE_PROJECT_NAME-sp"
functionAppName="$SOLACE_INTEGRATION_AZURE_PROJECT_NAME"
sku="Standard_LRS"

functions=(
  "solace-rdp-2-blob"
  # "another-function"
)

outputDir="$WORKING_DIR/azure"; mkdir -p $outputDir;
outputCreateFunctionAppStorageAccountFile="$outputDir/function.create-storage-account.json"
outputCreateFunctionAppServicePlanFile="$outputDir/function.create-appservice-plan.json"

echo " >>> Creating Resource Group ..."
  az group create \
    --name $resourceGroupName \
    --location "$azLocation" \
    --tags projectName=$SOLACE_INTEGRATION_AZURE_PROJECT_NAME \
    --verbose
  if [[ $? != 0 ]]; then echo " >>> ERROR: creating resource group"; exit 1; fi
echo " >>> Success."

echo " >>> Creating Function App Storage ..."
  az storage account create \
    --name $functionAppStorageAccountName \
    --resource-group $resourceGroupName \
    --location "$azLocation" \
    --sku $sku \
    --kind "StorageV2" \
    --tags projectName=$SOLACE_INTEGRATION_AZURE_PROJECT_NAME \
    --verbose \
    > $outputCreateFunctionAppStorageAccountFile
  if [[ $? != 0 ]]; then echo " >>> ERROR: creating function app storage"; exit 1; fi
  cat $outputCreateFunctionAppStorageAccountFile | jq .
echo " >>> Success."

echo " >>> Creating Function App Service Plan ..."
  az appservice plan create \
    --name $functionAppServicePlanName \
    --resource-group $resourceGroupName \
    --tags projectName=$SOLACE_INTEGRATION_AZURE_PROJECT_NAME \
    --verbose \
    > $outputCreateFunctionAppServicePlanFile
  if [[ $? != 0 ]]; then echo " >>> ERROR: creating function app service plan"; exit 1; fi
  cat $outputCreateFunctionAppServicePlanFile | jq .
echo " >>> Success."

echo " >>> Creating Function App ..."
  outputCreateFunctionAppFile="$outputDir/function.$functionAppName.create-function-app.json"
  az functionapp create \
    --name $functionAppName \
    --resource-group $resourceGroupName \
    --storage-account $functionAppStorageAccountName \
    --functions-version 3 \
    --plan $functionAppServicePlanName \
    --runtime "node" \
    --runtime-version "12" \
    --verbose \
    > $outputCreateFunctionAppFile
  if [[ $? != 0 ]]; then echo " >>> ERROR: creating function app: $functionAppName"; exit 1; fi
  cat $outputCreateFunctionAppFile | jq .
echo " >>> Success."

echo " >>> Add Function App Settings for every function ..."
  for function in ${functions[@]}; do
    echo " function:$function ..."
    if [ "$function" == "solace-rdp-2-blob" ]; then
      Rdp2BlobStorageConnectionString=$(echo $localSettings | jq -r '.Values.Rdp2BlobStorageConnectionString')
      Rdp2BlobStorageContainerName=$(echo $localSettings | jq -r '.Values.Rdp2BlobStorageContainerName')
      Rdp2BlobStoragePathPrefix=$(echo $localSettings | jq -r '.Values.Rdp2BlobStoragePathPrefix')
      outputFunctionAppConfigAppSettingsFile="$outputDir/function.$functionAppName.$function.config-appsettings.json"
      az functionapp config appsettings set \
        --name $functionAppName \
        --resource-group $resourceGroupName \
        --settings \
          "WEBSITE_RUN_FROM_PACKAGE=1" \
          "Rdp2BlobStorageConnectionString=$Rdp2BlobStorageConnectionString" \
          "Rdp2BlobStorageContainerName=$Rdp2BlobStorageContainerName" \
          "Rdp2BlobStoragePathPrefix=$Rdp2BlobStoragePathPrefix" \
          --verbose \
          > $outputFunctionAppConfigAppSettingsFile
        if [[ $? != 0 ]]; then echo " >>> ERROR: config app settings for function: $function"; exit 1; fi
        cat $outputFunctionAppConfigAppSettingsFile | jq .
    else
      echo " >>>ERROR: unknown settings for function=$function"; exit 1;
    fi
  done
echo " >>> Success."

# echo " >>> Creating Function Apps ..."
#   for function in ${functions[@]}; do
#     functionAppName="$SOLACE_INTEGRATION_AZURE_PROJECT_NAME-$function"
#     echo " functionAppName: $functionAppName"
#       outputCreateFunctionAppFile="$outputDir/function.$functionAppName.create-function-app.json"
#       az functionapp create \
#         --name $functionAppName \
#         --resource-group $resourceGroupName \
#         --storage-account $functionAppStorageAccountName \
#         --functions-version 3 \
#         --plan $functionAppServicePlanName \
#         --runtime "node" \
#         --runtime-version "12" \
#         --verbose \
#         > $outputCreateFunctionAppFile
#       if [[ $? != 0 ]]; then echo " >>> ERROR: creating function app: $functionAppName"; exit 1; fi
#       cat $outputCreateFunctionAppFile | jq
#
#       echo " adding function app settings ..."
#       if [ "$function" == "solace-rdp-2-blob" ]; then
#         Rdp2BlobStorageConnectionString=$(echo $localSettings | jq -r '.Values.Rdp2BlobStorageConnectionString')
#         Rdp2BlobStorageContainerName=$(echo $localSettings | jq -r '.Values.Rdp2BlobStorageContainerName')
#         Rdp2BlobStoragePathPrefix=$(echo $localSettings | jq -r '.Values.Rdp2BlobStoragePathPrefix')
#         outputFunctionAppConfigAppSettingsFile="$outputDir/function.$functionAppName.config-appsettings.json"
#         az functionapp config appsettings set \
#           --name $functionAppName \
#           --resource-group $resourceGroupName \
#           --settings \
#             "WEBSITE_RUN_FROM_PACKAGE=1" \
#             "Rdp2BlobStorageConnectionString=$Rdp2BlobStorageConnectionString" \
#             "Rdp2BlobStorageContainerName=$Rdp2BlobStorageContainerName" \
#             "Rdp2BlobStoragePathPrefix=$Rdp2BlobStoragePathPrefix" \
#             --verbose \
#             > $outputFunctionAppConfigAppSettingsFile
#           if [[ $? != 0 ]]; then echo " >>> ERROR: creating function app: $functionAppName"; exit 1; fi
#           cat $outputFunctionAppConfigAppSettingsFile | jq
#       else
#         echo " >>>ERROR: unknown settings for function=$function"; exit 1;
#       fi
#
#     echo " success: $functionAppName"
#   done
# echo " >>> Success."


###
# The End.
