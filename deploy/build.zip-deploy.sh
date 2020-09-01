#!/bin/bash
# ---------------------------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ---------------------------------------------------------------------------------------------

autoRun=$1
if [ -z "$autoRun" ]; then clear; fi

#####################################################################################
# settings
#
    scriptDir=$(cd $(dirname "$0") && pwd);
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
if [ -z "$autoRun" ]; then
  echo; read -n 1 -p "- Press key to continue, CTRL-C to exit ..." x; echo; echo
fi

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
npm install > /dev/null 2>&1
npm run build > /dev/null 2>&1
#####################################################################################
# Delete node-modules and re-install with production only
rm -rf node_modules
npm install --production > /dev/null 2>&1
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
  zip -r "$zipDeployDir/$function.v$packageVersion.zip" * > /dev/null 2>&1

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
