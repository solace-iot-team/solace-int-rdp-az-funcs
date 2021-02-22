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

  # localSettingsFile=$(assertFile $scriptName "$SOLACE_INTEGRATION_PROJECT_HOME/local.settings.json")
  # localSettings=$(cat $localSettingsFile | jq .)

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

    # too fast, let's sleep
    sleep 2m
    zipDeployFile=$(assertFile $scriptName "$releasePackagesDir/$function.v$packageVersion/$function.v$packageVersion.zip") || exit
    echo " >>> deploying function zip file: $zipDeployFile ..."
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

    # too fast, let's sleep
    sleep 2m
    echo " >>> retrieving function secrets ..."
      functionAppInfo=$(cat $outputFunctionAppShowFile | jq .)
      appId=$(echo $functionAppInfo | jq -r '.id')
      outputFunctionSecretsFile="$outputDir/function.$functionAppName.$function.secrets.json"
      az rest \
        --method post \
        --uri "$appId/functions/$function/listKeys?api-version=2018-11-01" \
        --verbose \
        > $outputFunctionSecretsFile
        if [[ $? != 0 ]]; then echo " >>> ERROR: retrieving function secrets: $functionAppName.$function"; exit 1; fi
        cat $outputFunctionSecretsFile | jq .
    echo " >>> success."
  done
echo " >>> Success."


# echo " >>> Retrieving Function Info ..."
#   rdpAppInfo=$(az functionapp show --name $functionAppAccountName --resource-group $resourceGroup)
#   if [[ $? != 0 ]]; then echo ">>> ERR: retrieving function app info."; exit 1; fi
# echo " >>> Success."
#
# echo "rdpAppInfo:"; echo $rdpAppInfo | jq
#
# echo " >>> Retrieving Function Keys ..."
#   rdpAppInfoId=$(echo $rdpAppInfo | jq -r '.id')
#   rdpAppkeys=$(az rest --method post --uri $rdpAppInfoId/functions/$functionName/listKeys?api-version=2018-11-01)
#   if [[ $? != 0 ]]; then echo ">>> ERR: retrieving function keys."; exit 1; fi
#   # echo $rdpAppkeys | jq .
#   rdpAppFuncCode=$( echo $rdpAppkeys | jq -r ".default")
#   # echo "rdpAppFuncCode=$rdpAppFuncCode"
# # add the code
#   export rdpAppFuncCode
#   export functionName
#   rdpAppInfo=$( echo $rdpAppInfo | jq -r '.functions."'$functionName'".code=env.rdpAppFuncCode' )
#   echo $rdpAppInfo | jq . > $outputDir/$outputFileFuncAppInfo
# echo " >>> Success."
#
#
#
#
# exit
#
# azLocation="$SOLACE_INTEGRATION_AZURE_LOCATION"
# functionAppStorageAccountName="solacerdpfuncappstorage"
# functionAppServicePlanName="$SOLACE_INTEGRATION_AZURE_PROJECT_NAME-sp"
# sku="Standard_LRS"
#
# functions=(
#   "solace-rdp-2-blob"
#   # "another-function"
# )
#
# outputDir="$WORKING_DIR/azure"; mkdir -p $outputDir;
# outputCreateFunctionAppStorageAccountFile="$outputDir/function.create-storage-account.json"
# outputCreateFunctionAppServicePlanFile="$outputDir/function.create-appservice-plan.json"
#
# echo " >>> Creating Resource Group ..."
#   az group create \
#     --name $resourceGroupName \
#     --location "$azLocation" \
#     --tags projectName=$SOLACE_INTEGRATION_AZURE_PROJECT_NAME \
#     --verbose
#   if [[ $? != 0 ]]; then echo " >>> ERROR: creating resource group"; exit 1; fi
# echo " >>> Success."
#
# echo " >>> Creating Function App Storage ..."
#   az storage account create \
#     --name $functionAppStorageAccountName \
#     --resource-group $resourceGroupName \
#     --location "$azLocation" \
#     --sku $sku \
#     --kind "StorageV2" \
#     --tags projectName=$SOLACE_INTEGRATION_AZURE_PROJECT_NAME \
#     --verbose \
#     > $outputCreateFunctionAppStorageAccountFile
#   if [[ $? != 0 ]]; then echo " >>> ERROR: creating function app storage"; exit 1; fi
#   cat $outputCreateFunctionAppStorageAccountFile | jq
# echo " >>> Success."
#
# echo " >>> Creating Function App Service Plan ..."
#   az appservice plan create \
#     --name $functionAppServicePlanName \
#     --resource-group $resourceGroupName \
#     --tags projectName=$SOLACE_INTEGRATION_AZURE_PROJECT_NAME \
#     --verbose \
#     > $outputCreateFunctionAppServicePlanFile
#   if [[ $? != 0 ]]; then echo " >>> ERROR: creating function app service plan"; exit 1; fi
#   cat $outputCreateFunctionAppServicePlanFile | jq
# echo " >>> Success."
#
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
#

###
# The End.
