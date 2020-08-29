#!/bin/bash

clear

#####################################################################################
# settings
#
    scriptDir=$(pwd)
    srcDir="$scriptDir/.."
    tmpDir="$scriptDir/tmp"
    zipDeployDir="$scriptDir/zip-deploy"
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
echo "# Zip-deploy dir : $zipDeployDir"

#####################################################################################
# get the version
#
packageVersion=$(node -p -e "require('$srcDir/package.json').version")
if [[ $? != 0 ]]; then echo " >>> ERR: get package version via node binary"; exit 1; fi
echo "# Version        : $packageVersion"
echo; read -n 1 -p "- Press key to continue, CTRL-C to exit ..." x; echo; echo

#####################################################################################
# Prepare Dirs
mkdir $tmpDir > /dev/null 2>&1
rm -rf $tmpDir/*
mkdir $zipDeployDir > /dev/null 2>&1
rm -rf $zipDeployDir/*
zipDeployTmp=$zipDeployDir/tmp
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
npm install --production > /dev/null 2>&1
npm run build > /dev/null 2>&1
#####################################################################################
# Build zip files
for function in ${functions[@]}; do
  echo " >>> Function: $function"; echo
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
  # create the zip file
  cd $zipDeployTmp
  zip -r "$zipDeployDir/$function-v$packageVersion.zip" * > /dev/null 2>&1

done
#####################################################################################
# Cleanup

rm -rf $tmpDir
rm -rf $zipDeployTmp

echo "##########################################################################################"
echo "# Packages dir  : $zipDeployDir"
echo "# Packages built:"
cd $zipDeployDir
ls -la *.zip
echo
echo

###
# The End.
