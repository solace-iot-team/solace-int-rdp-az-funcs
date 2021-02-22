# Release

## Environment Variables

````bash
export SOLACE_INTEGRATION_PROJECT_HOME="{local path to solace-int-rdp-az-funcs}"

# optional:
export WORKING_DIR="local path to a working dir"
  # default:
  export WORKING_DIR="$SOLACE_INTEGRATION_PROJECT_HOME/tmp"
````

## Build Release Packages

````bash
./build.release-packages.sh

# output:
$WORKiNG_DIR/release-packages/{function}.v{version}.zip
$WORKiNG_DIR/release-packages/{function}.v{version}/{function}.v{version}.zip
$WORKiNG_DIR/release-packages/{function}.v{version}/template.app.settings.zip
````


----
