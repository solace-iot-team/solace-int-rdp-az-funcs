# Test

### Prerequisites
* Azure Account
* Azure CLI
* bash
* [jq](https://stedolan.github.io/jq/download/)

````bash
# list available Azure locations
az login
az appservice list-locations --sku F1
````

### Environment Variables

````bash
export SOLACE_INTEGRATION_PROJECT_HOME="{local path to solace-int-rdp-az-funcs}"
export SOLACE_INTEGRATION_AZURE_PROJECT_NAME="{unique project name}"
export SOLACE_INTEGRATION_AZURE_LOCATION="{azure location}"

# optional:
export WORKING_DIR="local path to a working dir"
  # default:
  export WORKING_DIR="$SOLACE_INTEGRATION_PROJECT_HOME/tmp"
````

## Local Test with Azure Blob Storage

````bash
az login

azure/create.az.blob-storage.sh
# output:
$WORKiNG_DIR/azure/info.blob-storage.json
$WORKiNG_DIR/azure/secrets.blob-storage.json

generate.local.settings.sh
# output:
$SOLACE_INTEGRATION_PROJECT_HOME/local.settings.json

# start function locally either with npm or visual studio code
npm start

(visual studio code => start/debug)

post-events-to-func.sh

(check azure blob container)
````

## Unit Test
````bash
run.npm.unit-tests.sh
````

## Integration Test

**Azure Login:**
````bash
az login
````
**Run All Tests Below:**
````bash
run.sh
````

**Azure Blob Storage:**
````bash
azure/create.az.blob-storage.sh
# output:
$WORKiNG_DIR/azure/info.blob-storage.json
$WORKiNG_DIR/azure/secrets.blob-storage.json
````
**Generate Local Settttings:**
````bash
./generate.local.settings.sh
# output:
$SOLACE_INTEGRATION_PROJECT_HOME/local.settings.json
````

**Build Release Packages:**
[Build Release Packages.](../release)
````bash
../release/build.release-packages.sh
````

**Azure Function App:**
````bash
azure/create.az.function-resources.sh
# output:
$WORKiNG_DIR/azure/function.create-appservice-plan.json
$WORKiNG_DIR/azure/function.create-storage-account.json
# per function
$WORKiNG_DIR/azure/function.{functionapp-name}.create-function-app.json
$WORKiNG_DIR/azure/function.{functionapp-name}.config-appsettings.json
````

**Azure zip deploy functions:**
````bash
azure/deploy.az.functions.sh
# output:
$WORKiNG_DIR/azure/function.{functionapp-name}.info.json
# per function
$WORKiNG_DIR/azure/function.{functionapp-name}.{function}.zip-deploy.json
$WORKiNG_DIR/azure/function.{functionapp-name}.{function}.secrets.json
````

**Generate Integration Settings:**
````bash
generate.integration.settings.sh
# output:
$WORKiNG_DIR/integration.settings.json
````

**Run Integration Tests:**
````bash
run.npm.integration-tests.sh
````

---
## Delete Azure Resources
````bash
azure/delete.az.resources.sh
````




---
