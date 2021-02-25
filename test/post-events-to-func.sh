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

  localSettingsFile=$(assertFile $scriptName "$SOLACE_INTEGRATION_PROJECT_HOME/local.settings.json")
  localSettings=$(cat $localSettingsFile | jq .)
  functionHost="127.0.0.1"
  functionPort=$(echo $localSettings | jq -r '.Host.LocalHttpPort')
  functionPath="api/solace-rdp-2-blob"

  topics=(
    "topic-1/level-1/level-2/level-3"
    "topic-2/level-1/level-2/level-3"
  )

  ############################################################################################################################
  # Run

  echo " >>> Sending messages ..."

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
    # _functionParams="path=''&pathCompose=withTime&code=xyz"
    _functionUrl="http://$functionHost:$functionPort/$functionPath?$_functionParams"

    echo " >>> sending:"
    echo "     function url: $_functionUrl"
    echo "     topic: $topic"
    echo "     payload: $payload"

    echo $payload | curl \
      -H "Content-Type: application/json" \
      -X POST \
      -i $_functionUrl \
      -d @- \
      # -v \

      if [[ $? != 0 ]]; then echo; echo ">>> ERROR. aborting."; echo; exit 1; fi

      echo ----------------------------------------------

  done


###
# The End.
