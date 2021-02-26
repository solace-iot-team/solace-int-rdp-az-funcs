#!/usr/bin/env bash
scriptDir=$(cd $(dirname "$0") && pwd);
scriptName=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
if [ -z "$SOLACE_INTEGRATION_PROJECT_HOME" ]; then echo ">>> ERROR: - $scriptName - missing env var: SOLACE_INTEGRATION_PROJECT_HOME"; exit 1; fi
source $SOLACE_INTEGRATION_PROJECT_HOME/.lib/functions.sh


############################################################################################################################
# Environment Variables

  if [ -z "$LOG_DIR" ]; then export LOG_DIR="$SOLACE_INTEGRATION_PROJECT_HOME/logs"; mkdir -p $LOG_DIR; fi
  if [ -z "$WORKING_DIR" ]; then export WORKING_DIR="$SOLACE_INTEGRATION_PROJECT_HOME/tmp"; mkdir -p $WORKING_DIR; fi


#####################################################################################
# settings
#
    srcDir="$SOLACE_INTEGRATION_PROJECT_HOME"
    zipDeployRootDir="$WORKING_DIR/release-packages"; mkdir -p $zipDeployRootDir; rm -rf $zipDeployRootDir/*;
    zipDeployWorkingDir="$zipDeployRootDir/project-tmp"; mkdir -p $zipDeployWorkingDir;
    zipDeployFunctionsWorkingDir="$zipDeployRootDir/functions-tmp"; mkdir -p $zipDeployFunctionsWorkingDir;
    assetDir="$SOLACE_INTEGRATION_PROJECT_HOME/release/assets"

    functions=(
      "solace-rdp-2-blob"
      # "another-function"
    )
    functionLibs=(
      "solace-rdp-lib"
    )
    projectFunctionFiles=(
      "package.json"
      "package-lock.json"
      "proxies.json"
      "host.json"
    )

# TODO: folder: solace-rdp-to-blob
#   function.json ==> required
#   # try without sample.dat


############################################################################################################################
# Run
echo ">>> retrieving version ..."
  # the version is the same across all functions
  packageVersion=$(node -p -e "require('$srcDir/package.json').version")
  if [[ $? != 0 ]]; then echo ">>> ERROR: get package version via node binary"; exit 1; fi
  echo " version: $packageVersion"
echo ">>> success."

#####################################################################################
# Copy Sources
echo ">>> gather source files ..."
  for function in ${functions[@]}; do
    cp -r "$srcDir/$function" $zipDeployWorkingDir
  done
  for functionLib in ${functionLibs[@]}; do
    cp -r "$srcDir/$functionLib" $zipDeployWorkingDir
  done
  for projectFunctionFile in ${projectFunctionFiles[@]}; do
    cp "$srcDir/$projectFunctionFile" $zipDeployWorkingDir
  done
echo ">>> success."

#####################################################################################
# Build the project
echo ">>> compile ..."
  cp "$srcDir/tsconfig.json" $zipDeployWorkingDir
  cd $zipDeployWorkingDir
  npm install
  npm run build
  rm "$zipDeployWorkingDir/tsconfig.json"
echo ">>> success."

#####################################################################################
# Delete node-modules and re-install with production only
echo ">>> installing production node modules only ..."
  cd $zipDeployWorkingDir
  rm -rf node_modules
  npm install --production
echo ">>> success."

#####################################################################################
# Build zip files
echo ">>> build function release zip files ..."
  rm -rf $zipDeployFunctionsWorkingDir/*
  for function in ${functions[@]}; do
    echo " function: $function"

    # cd $zipDeployWorkingDir
    zipDeployFunctionWorkingDir="$zipDeployFunctionsWorkingDir/$function"; mkdir -p $zipDeployFunctionWorkingDir
    mkdir -p "$zipDeployFunctionWorkingDir/$function"
    zipDeployFunctionReleaseDir="$zipDeployRootDir/$function.v$packageVersion"; mkdir -p $zipDeployFunctionReleaseDir
    zipDeployFunctionReleaseZipFile="$zipDeployFunctionReleaseDir/$function.v$packageVersion.zip";

    # copy specific function files
    cp "$zipDeployWorkingDir/$function/function.json" "$zipDeployFunctionWorkingDir/$function/function.json"
    cp "$zipDeployWorkingDir/$function/sample.dat" "$zipDeployFunctionWorkingDir/$function/sample.dat"
    # copy project function files
    for projectFunctionFile in ${projectFunctionFiles[@]}; do
      cp "$zipDeployWorkingDir/$projectFunctionFile" $zipDeployFunctionWorkingDir
    done

    # copy functions *.js files in dist
    rsync -a --include='*.js' -f 'hide,! */' "$zipDeployWorkingDir/dist/$function" "$zipDeployFunctionWorkingDir/dist"
    # copy lib *.js files in dist
    for functionLib in ${functionLibs[@]}; do
      rsync -a --include='*.js' -f 'hide,! */' "$zipDeployWorkingDir/dist/$functionLib" "$zipDeployFunctionWorkingDir/dist"
    done

    # copy node_modules
    cp -r "$zipDeployWorkingDir/node_modules" $zipDeployFunctionWorkingDir

    # create the zip file
    cd $zipDeployFunctionWorkingDir
    zip -r "$zipDeployFunctionReleaseZipFile" *
    # copy the rest of the files
    cp "$zipDeployWorkingDir/$function/template.app.settings.json" $zipDeployFunctionReleaseDir

    # zip the release package
    cd $zipDeployFunctionReleaseDir
    zip "$zipDeployFunctionReleaseDir.zip" *

    echo " >>> done."
    echo " ------------------------------------------------------------------------"
  done
echo ">>> success."

#####################################################################################
# Cleanup
echo ">>> cleanup and list ..."
  rm -rf $zipDeployWorkingDir
  rm -rf $zipDeployFunctionsWorkingDir
  ls -l $zipDeployRootDir/*
echo ">>> success."


###
# The End.
