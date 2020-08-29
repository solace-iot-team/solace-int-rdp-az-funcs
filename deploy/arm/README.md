# Deploy to Azure using ARM Templates

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
---
The End.
