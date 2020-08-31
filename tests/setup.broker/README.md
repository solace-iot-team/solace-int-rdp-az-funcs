# Setup Broker

## Pre-requisites

* [Create Azure Resources & Deploy](../../deploy).
* [Download Azure Root Certificate](https://cacerts.digicert.com/BaltimoreCyberTrustRoot.crt.pem).

## Prepare Setup Broker

````bash
cp template.settings.az-func.yml settings.az-func.yml
vi settings.az-func.yml

  # enter values

````

## Setup Broker

````bash
./start.local.broker.sh
./run.create-rdp.sh
````

---
The End.
