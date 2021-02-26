#!/usr/bin/env bash

scriptDir=$(cd $(dirname "$0") && pwd);
scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
if [ -z "$SOLACE_INTEGRATION_PROJECT_HOME" ]; then echo ">>> ERROR: - $scriptName - missing env var: SOLACE_INTEGRATION_PROJECT_HOME"; exit 1; fi
source $SOLACE_INTEGRATION_PROJECT_HOME/.lib/functions.sh

############################################################################################################################
# Environment Variables

  if [ -z "$WORKING_DIR" ]; then export WORKING_DIR="$SOLACE_INTEGRATION_PROJECT_HOME/tmp"; mkdir -p $WORKING_DIR; fi
  if [ -z "$LOG_DIR" ]; then export LOG_DIR="$WORKING_DIR/logs"; mkdir -p $LOG_DIR; fi

############################################################################################################################
# Settings

  brokerRestHost="localhost"
  brokerRestPort=9000
  outputDir="$WORKING_DIR/solace-broker"; mkdir -p $outputDir;
  resultFile="$outputDir/post-events-to-broker.result.json"
  # topic pattern: {domain}/{id}
  domain="solace-rdp-2-blob"

############################################################################################################################
# Run

  msgSentCounter=0
  for i in {1..100}; do
    echo " >>> sending event batch number: $i"
      ((msgSentCounter++))
      topic="$domain/$msgSentCounter"
      echo "   >> ($msgSentCounter)-topic: $topic"
      timestamp=$(date +"%Y-%m-%dT%T.%3NZ")
      payload='
      {
        "header": {
          "topic": "'"$topic"'",
          "timestamp": "'"$timestamp"'",
          "eventBatchNum": "'"$i"'"
        },
        "body": {
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

  timestamp=$(date +"%Y-%m-%dT%T.%3NZ")
  resultJSON='
  {
      "timestamp": "'"$timestamp"'",
      "numberMsgsSent": "'"$msgSentCounter"'"
  }
  '
  echo $resultJSON | jq . > $resultFile
  cat $resultFile | jq .

# The End.
