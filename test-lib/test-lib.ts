// Copyright (c) 2021, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
// All rights reserved.
// Licensed under the MIT License.

import { ContainerClient } from "@azure/storage-blob" 
import fetch, { RequestInit, Response } from "node-fetch";

export interface AzureFunctionSettings {
    code: string,
    host: string,
    port: number,
    route: string
}

export interface AzureStorageSettings {
    account_name: string,
    connection_string: string,
    container_name: string,
    path_prefix: string
}
export interface AzureIntegrationSettings {
    function: AzureFunctionSettings,
    storage: AzureStorageSettings
}

export interface AzureFunctionCallPayload {
    meta: {
        topic?: string,
        timestamp: string
    },
    body: {
        metric_1: number,
        metric_2: number
    }
}

export class AzureFunctionCall {
    private baseUri : string;
    private settings: AzureFunctionSettings;
    private static max_retries: number = 30;
    private static retry_delay_millis: number = 5000;
    
    public static topic_1: string = "topic-1/level-1/level-2/level-3";
    public static topic_2: string = "topic-2/level-1/level-2/level-3";

    constructor(azureIntegrationSettings : AzureIntegrationSettings) { 
        this.settings = azureIntegrationSettings.function;
        this.baseUri =  "https://" + 
                        this.settings.host + 
                        ":" + this.settings.port +
                        "/" + this.settings.route +
                        "?code=" + this.settings.code;
    }
    private _postMessage = async(query_params: Array<string>, payload: AzureFunctionCallPayload): Promise<Response> => {
        const request: RequestInit = {
            method: "POST",
            body: JSON.stringify(payload)
        };
        const uri = this.baseUri + "&" + query_params.join('&');
        console.log(`[postMessage] - uri=${uri}`)
        console.log(`[postMessage] - body=${request.body}`)
        return await fetch(uri, request)
    }
    postMessage = async(query_params: Array<string>, payload: AzureFunctionCallPayload): Promise<Response> => {
        let retries = 0;
        let status = 400;
        let response: Response = null;
        while (status != 200 && retries < AzureFunctionCall.max_retries) {
            console.log(`[postMessage] - try number: ${retries+1}`);
            response = await this._postMessage(query_params, payload);
            console.log(`[postMessage] - response.status = ${response.status}`);
            status = response.status;
            retries += 1;                
            if(status != 200) await sleep(AzureFunctionCall.retry_delay_millis);
        }
        return response;
    }
    generatePayload = (topic: string): AzureFunctionCallPayload => {
        const d = new Date();
        return {
            meta: {
                topic: topic,
                timestamp: d.toLocaleDateString()
            },
            body: {
                metric_1: 1,
                metric_2: 2
            }
        }
    }
}

export function sleep(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}

export async function streamToString(readableStream: NodeJS.ReadableStream) {
    return new Promise((resolve, reject) => {
        const chunks:string[] = [];
        readableStream.on("data", (data) => {
            chunks.push(data.toString());
        });
        readableStream.on("end", () => {
            resolve(chunks.join(""));
        });
        readableStream.on("error", reject);
    });
}

export async function deleteContainerIfExists(containerClient: ContainerClient, do_wait: boolean = true) : Promise<boolean> {
    let exists = await containerClient.exists();
    if(exists) {
        console.log(`[deleteContainer] - marking container for deletion`);
        const deleteContainerResponse = await containerClient.delete();
        // console.log(`[deleteContainer] - deleteContainerResponse = ${JSON.stringify(deleteContainerResponse, null, 2)}`);
        if(do_wait) {
            // deletion doesn't happen instantly but during garbage collection
            // operations blocked at least 30 seconds
            console.log(`[deleteContainer] - sleeping for 1 minute ...`);
            await sleep(60000);    
            console.log(`[deleteContainer] - done.`);
        }
    } else {
        console.log(`[deleteContainer] - nothing to do`);
    }
    return true;
}

export interface BlobCount {
    fileCount: number,
    dirCount: number
}

export async function countBlobs(containerClient: ContainerClient) : Promise<BlobCount> {
    let blobCount: BlobCount = {
        fileCount: 0,
        dirCount: 0
    };
    for await(const response of containerClient.listBlobsFlat().byPage({ maxPageSize: 100 })) {
        for(const blob of response.segment.blobItems) {
            if(blob.properties.contentLength > 0) {
                blobCount.fileCount++;
            } else {
                blobCount.dirCount++;
            }
        }
    }
    console.log(`[countBlobs] - blobCount = ${JSON.stringify(blobCount, null, 2)}`);
    return blobCount;
}
