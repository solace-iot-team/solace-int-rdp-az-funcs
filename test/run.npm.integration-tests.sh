#!/usr/bin/env bash

scriptDir=$(cd $(dirname "$0") && pwd);
scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));

runScript="npm run integration-tests"
  if [[ "$RUN_FG" == "false" ]]; then
    logFile="$LOG_DIR/$scriptName.out"; mkdir -p "$(dirname "$logFile")";
    $runScript > $logFile 2>&1
  else
    $runScript
  fi
  code=$?; if [[ $code != 0 ]]; then echo ">>> ERROR - code=$code - runScript='$runScript' - $scriptName"; FAILED=1; fi

###
# The End.
