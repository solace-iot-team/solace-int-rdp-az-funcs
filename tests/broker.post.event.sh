#!/bin/bash

clear
echo; echo "##############################################################################################################"
echo
echo "# Script: "$(basename $(test -L "$0" && readlink "$0" || echo "$0"));


brokerRestHost="localhost"
brokerRestPort=9000

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
  "$domain/$assetTypeId/$assetId/$regionId/$dataTypeId_1"
  "$domain/$assetTypeId/$assetId/$regionId/$dataTypeId_2"
)

for i in {1..100}; do
  echo " >>> sending event batch number: $i"
  for topic in ${topics[@]}; do
    echo "   >> topic: $topic"
    timestamp=$(date +"%Y-%m-%dT%T.%3NZ")
    payload='
    {
      "meta": {
        "topic": "'"$topic"'",
        "timestamp": "'"$timestamp"'",
        "eventBatchNum": "'"$i"'"
      },
      "event": {
        "metric-1": 100,
        "metric-2": 200
      }
    }
    '
    _brokerUrl="http://$brokerRestHost:$brokerRestPort/$topic"
    echo $payload | curl \
      -H "Content-Type: application/json" \
      -H "Solace-delivery-mode: direct" \
      -X POST \
      $_brokerUrl \
      -d @- \
      # -v \
    if [[ $? != 0 ]]; then echo ">>> ERROR ..."; echo; exit 1; fi
  done
done

echo
echo
# The End.
