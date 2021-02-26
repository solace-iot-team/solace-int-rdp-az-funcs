# Solace Integration: RDP to Azure Functions

[![tests](https://github.com/solace-iot-team/solace-int-rdp-az-funcs/actions/workflows/tests.yml/badge.svg)](https://github.com/solace-iot-team/solace-int-rdp-az-funcs/actions/workflows/tests.yml)

Integrations of Solace with Azure Functions using the Solace Rest Delivery Point (RDP).

[Issues](https://github.com/solace-iot-team/solace-int-rdp-az-funcs/issues) |
[Release Notes](./ReleaseNotes.md) |

## solace-rdp-2-blob

Azure Function integrating Solace RDP to Azure Storage (Blob).

Sequence:
- message ==> Solace Broker
- Solace Broker Rest Delivery Point ==> Azure Function (solace-rdp-2-blob)
- Azure Function ==> Azure Storage


### Azure Storage

- Account kind: StorageV2
- Hierarchical namespace: enabled

### Azure Function
[See also test directory for Build, Deploy, Test.](./test)

**Configuration:**

[See ./solace-rdp-2-blob/template.app.settings.json](./solace-rdp-2-blob/template.app.settings.json)

* **Rdp2BlobStorageContainerName**
  - container name
* **Rdp2BlobStoragePathPrefix**
  - fixed path prefix for each file
* **Rdp2BlobStorageConnectionString**
  - connection string for the data lake storage account


**URI Query Parameters:**

* **path**="{level-1/level-2/level-3/...}" - string, can be empty
  - multi-level path for the file (message) in the Blob Storage
  - appended to the _Rdp2BlobStoragePathPrefix_ configuration setting

* **pathCompose**=["withTime"], optional
  - _withTime_
    - generates a time-based storage path: YYYY/MM/DD/MM
    - appended to _Rdp2BlobStoragePathPrefix/path_

**Ouptut:**

|http code|description|
|---|---|
|200   | ok, file written to storage  |
|400   | bad request. return for config errors & query parameter errors  |
|4xx   | pass-through of Azure blob storage REST Api  |

Console log:
- ERROR details in case of any errors


## Dev & Test

[See test directory.](./test)

---
