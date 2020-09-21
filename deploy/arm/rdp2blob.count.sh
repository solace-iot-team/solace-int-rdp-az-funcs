#!/bin/bash
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
# All rights reserved.
# Licensed under the MIT License.

autoRun=$1
if [ -z "$autoRun" ]; then clear; fi

#####################################################################################
# settings
#
  scriptDir=$(cd $(dirname "$0") && pwd);
  scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
  projectHome=${scriptDir%%/deploy/*}
  deploymentDir="$projectHome/.deployment"

  funcAppInfoFile="$deploymentDir/rdp2blob.add-settings.output.json"
  outputDir="$deploymentDir"
  outputFile="$outputDir/rdp2blob.count.output.json"
  if [ ! -z "$autoRun" ]; then
    countResultOutputFile=$autoRun
  fi

#####################################################################################
# run
#
  funcAppInfoJSON=$(cat $funcAppInfoFile | jq)
  dlConnectionString=$( echo $funcAppInfoJSON | jq -r '.[] | select(.name == "Rdp2BlobStorageConnectionString").value' )
  dlContainerName=$( echo $funcAppInfoJSON | jq -r '.[] | select(.name == "Rdp2BlobStorageContainerName").value' )
  dlPathPrefix=$( echo $funcAppInfoJSON | jq -r '.[] | select(.name == "Rdp2BlobStoragePathPrefix").value' )

echo " >>> Retrieving blob file list ..."
  az storage blob list  --container-name $dlContainerName \
                        --prefix $dlPathPrefix \
                        --connection-string $dlConnectionString \
                        --query "[?properties.contentLength > \`0\`].name" \
                        --num-results "*" \
                        > $outputFile
  if [[ $? != 0 ]]; then echo " >>> ERR: retrieving blob file list"; exit 1; fi
echo " >>> Success."

echo " >>> Counting number of lines ..."
  numLines=$(wc -l < $outputFile)
  # subtract first & last line (array brackets)
  ((numFiles = numLines - 2))
echo " >>> Success."

if [ ! -z "$countResultOutputFile" ]; then
  timestamp=$(date +"%Y-%m-%dT%T.%3NZ")
  resultJSON='
  {
      "timestamp": "'"$timestamp"'",
      "numberBlobFiles": "'"$numFiles"'"
  }
  '
  echo $resultJSON | jq > $countResultOutputFile
fi

echo
echo "******************************************************************************"
echo
echo "Container: $dlContainerName"
echo "Path: $dlPathPrefix"
echo "Number of files: $numFiles"
echo


## The End.
#
