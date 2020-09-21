#!/bin/bash
# ---------------------------------------------------------------------------------------------
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
# All rights reserved.
# Licensed under the MIT License.
# ---------------------------------------------------------------------------------------------

clear
echo; echo "##############################################################################################################"
echo
echo "# Script: "$(basename $(test -L "$0" && readlink "$0" || echo "$0"));


functionHost="127.0.0.1"
functionPort=7071
functionPath="api/solace-rdp-2-blob"

# topic pattern: {domain}/{asset-type-id}/{asset-id}/{region-id}/{data-type-id}
domain="as-iot-assets"
assetTypeId="asset-type-a"
assetId="asset-id-1"
regionId="region-id-1"
dataTypeId_0="stream-metrics"
dataTypeId_1="stream-metrics-1"
dataTypeId_2="stream-metrics-2"

topics=(
  "$domain/$assetTypeId/$assetId/$regionId/$dataTypeId_0"
  # "$domain/$assetTypeId/$assetId/$regionId/$dataTypeId_1"
  # "$domain/$assetTypeId/$assetId/$regionId/$dataTypeId_2"
)

for topic in ${topics[@]}; do

  timestamp=$(date +"%Y-%m-%dT%T.%3NZ")

  payload='
  {
    "meta": {
      "topic": "'"$topic"'",
      "timestamp": "'"$timestamp"'"
    },
    "event": {
      "metric-1": 100,
      "metric-2": 200
    }
  }
  '
  # test with empty payload
  # payload=


  _functionParams="path=$topic&pathCompose=withTime&code=xyz"
  _functionParams="path=''&pathCompose=withTime&code=xyz"
  _functionUrl="http://$functionHost:$functionPort/$functionPath?$_functionParams"

    echo ----------------------------------------------
    echo "function url: $_functionUrl"
    echo "topic: $topic"
    echo "payload: $payload"
    echo ----------------------------------------------

  echo $payload | curl \
    -H "Content-Type: application/json" \
    -X POST \
    $_functionUrl \
    -d @- \
    # -v \

    if [[ $? != 0 ]]; then echo; echo ">>> ERROR. aborting."; echo; exit 1; fi

done

echo
echo
###
# The End.