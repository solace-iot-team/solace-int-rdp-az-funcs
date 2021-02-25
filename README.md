# Solace Integration: RDP to Azure Functions


TODO: badge
TODO: describe paramters for rdp-2-blob function

This repository is for active development of the integrations of Solace REST Delivery Point (RDP) to Azure Functions.
For consumers and project examples we recommend visiting [solace-integration/solace-rdp-az-functions](xxx).


**!!!!!!!!    UNDER CONSTRUCTION    !!!!!!!!**

## Links
[Issues](https://github.com/solace-iot-team/solace-int-rdp-az-funcs/issues) |
[Project Samples](xxx) |

## Pre-Requisites

* node.js
* [Azure CLI](https://docs.microsoft.com/en-gb/cli/azure/install-azure-cli-macos?view=azure-cli-latest)
* Visual Studio Code
* [Azure Functions Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurefunctions)

## Getting Started

### Visual Studio Code

Open the workspace: `solace-int-rdp-az-funcs.code-workspace`.

### Manual
````bash
cp template.local.settings.json local.settings.json

vi local.settings.json
 # add configuration

````

````bash
npm install

npm run build

npm run start

````

### Send Events to Function

````bash

cd tests
./func.post.event.sh

````

## More

[Deploy](./deploy).

---
The End.
