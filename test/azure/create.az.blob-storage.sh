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
azLocation="$SOLACE_INTEGRATION_AZURE_LOCATION"
dataLakeAccountName="solacedatalake"
sku="Standard_LRS"

outputDir="$WORKING_DIR/azure"; mkdir -p $outputDir; rm -rf $outputDir/*;
outputInfoFile="$outputDir/info.blob-storage.json"
outputSecretsFile="$outputDir/secrets.blob-storage.json"

echo " >>> Creating Resource Group ..."
  az group create \
    --name $resourceGroupName \
    --location "$azLocation" \
    --tags projectName=$SOLACE_INTEGRATION_AZURE_PROJECT_NAME \
    --verbose
  if [[ $? != 0 ]]; then echo " >>> ERROR: creating resource group"; exit 1; fi
echo " >>> Success."

echo " >>> Creating Blob Storage ..."
  az storage account create \
    --name $dataLakeAccountName \
    --resource-group $resourceGroupName \
    --location "$azLocation" \
    --sku $sku \
    --enable-hierarchical-namespace "true" \
    --tags projectName=$SOLACE_INTEGRATION_AZURE_PROJECT_NAME \
    --verbose \
    > $outputInfoFile
  if [[ $? != 0 ]]; then echo " >>> ERROR: creating blob storage"; exit 1; fi
  cat $outputInfoFile | jq .
echo " >>> Success."

echo " >>> Retrieve the Storage Account Connection Strings ..."
  az storage account show-connection-string \
    --name $dataLakeAccountName \
    --resource-group $resourceGroupName \
    --verbose \
    > $outputSecretsFile
  if [[ $? != 0 ]]; then echo " >>> ERROR: retrieving storage account connection strings"; exit 1; fi
  cat $outputSecretsFile | jq .
echo " >>> Success."

###
# The End.
