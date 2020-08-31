# Deploy to Azure using ARM Templates

## Stuff

````bash
# create an app setting
az functionapp config appsettings set --name <FUNCTION_APP_NAME> \
--resource-group <RESOURCE_GROUP_NAME> \
--settings CUSTOM_FUNCTION_APP_SETTING=12345
````

````bash
# disable a function app
az functionapp config appsettings set --name <myFunctionApp> \
--resource-group <myResourceGroup> \
--settings AzureWebJobs.QueueTrigger.Disabled=true
````

````bash
# enable a function app
az functionapp config appsettings set --name <myFunctionApp> \
--resource-group <myResourceGroup> \
--settings AzureWebJobs.QueueTrigger.Disabled=false
````


## Pre-Requisites

* bash
* jq
* Azure CLI

## Login
````bash
az login

az account set --subscription YOUR-SUBSCRIPTION-NAME-OR-ID
````

## Configure General Settings
````bash
vi settings.json
    # update settings
````

## Configure ARM Parameters

````bash
vi parameters.json
    # update the parameters
````    

## Deploy
````bash
./deploy.sh

````

## Delete Deployment
````bash
./delete.deployment.sh
````

## Check / List Resources

````bash
# get the appsettings
az functionapp config appsettings list --name <FUNCTION_APP_NAME> \
--resource-group <RESOURCE_GROUP_NAME>
````
---
The End.
