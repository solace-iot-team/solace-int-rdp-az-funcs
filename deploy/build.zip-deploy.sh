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
    srcDir="$scriptDir/.."
    tmpDir="$scriptDir/tmp"
    zipDeployRootDir="$scriptDir/zip-deploy"
    functions=(
      "solace-rdp-2-blob"
    )
    functionFiles=(
      "package.json"
      "proxies.json"
    )


echo
echo "##########################################################################################"
echo "# Build zip file(s) to deploy to Azure"
echo "# Sources        : '$srcDir'"
echo "# Functions      : '${functions[@]}'"
echo "# Zip-deploy dir : $zipDeployRootDir"

#####################################################################################
# get the version
# the version is the same across all functions
#
packageVersion=$(node -p -e "require('$srcDir/package.json').version")
if [[ $? != 0 ]]; then echo " >>> ERR: get package version via node binary"; exit 1; fi
echo "# Version        : $packageVersion"
if [ -z "$autoRun" ]; then
  echo; read -n 1 -p "- Press key to continue, CTRL-C to exit ..." x; echo; echo
fi

#####################################################################################
# Prepare Dirs
mkdir $tmpDir > /dev/null 2>&1
rm -rf $tmpDir/*
mkdir $zipDeployRootDir > /dev/null 2>&1
rm -rf $zipDeployRootDir/*
zipDeployTmp=$zipDeployRootDir/tmp
mkdir $zipDeployTmp

#####################################################################################
# Copy Sources
cp -r $srcDir/solace-rdp-lib $tmpDir
cp $srcDir/tsconfig.json $tmpDir
cp $scriptDir/deploy.host.json $tmpDir/host.json
for function in ${functions[@]}; do
  cp -r $srcDir/$function $tmpDir
done
for functionFile in ${functionFiles[@]}; do
  cp $srcDir/$functionFile $tmpDir
done
#####################################################################################
# Build the project
cd $tmpDir
npm install > /dev/null 2>&1
npm run build > /dev/null 2>&1
#####################################################################################
# Delete node-modules and re-install with production only
rm -rf node_modules
npm install --production > /dev/null 2>&1
#####################################################################################
# Build zip files
for function in ${functions[@]}; do
  echo " >>> Function: $function"
  cd $tmpDir
  rm -rf $zipDeployTmp/*
  # specific function files
  mkdir $zipDeployTmp/$function
  cp ./$function/function.json "$zipDeployTmp/$function/function.json"
  cp ./$function/sample.dat "$zipDeployTmp/$function/sample.dat"

  # copy all *.js files in dist
  rsync -a --include='*.js' -f 'hide,! */' ./dist $zipDeployTmp
  # copy node_modules
  cp -r node_modules $zipDeployTmp
  # copy the rest
  cp ./host.json $zipDeployTmp
  cp ./package.json $zipDeployTmp
  cp ./package-lock.json $zipDeployTmp
  cp ./proxies.json $zipDeployTmp
  # create the function dir
  zipDeployDir="$zipDeployRootDir/$function.v$packageVersion"
  mkdir $zipDeployDir
  # create the zip file
  cd $zipDeployTmp
  zip -r "$zipDeployDir/$function.v$packageVersion.zip" * > /dev/null 2>&1
  # copy the rest of the files
  cp "$tmpDir/$function/template.app.settings.json" $zipDeployDir
  echo " >>> done."
done
echo
#####################################################################################
# Cleanup

rm -rf $tmpDir
rm -rf $zipDeployTmp

echo "##########################################################################################"
echo "# Packages dir  : $zipDeployRootDir"
echo "# Packages built:"
cd $zipDeployRootDir
ls -la */*.*
echo
echo

###
# The End.
