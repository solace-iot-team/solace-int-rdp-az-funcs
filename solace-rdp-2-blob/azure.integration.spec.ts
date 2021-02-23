// Copyright (c) 2021, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
// All rights reserved.
// Licensed under the MIT License.

import "mocha";
import * as chai from "chai";
const expect = chai.expect;
import * as chaiAsPromised from "chai-as-promised";
chai.use(chaiAsPromised);
// import * as sinon from "sinon";
import * as sinonChai from "sinon-chai";
chai.use(sinonChai);
// import rewire = require("rewire");
import path = require("path");
import fetch, { RequestInit, Response } from "node-fetch";

// import { Context, Logger } from "@azure/functions";
import { BlobDownloadResponseModel, BlobServiceClient, BlockBlobClient, ContainerClient, ContainerDeleteIfExistsResponse } from "@azure/storage-blob" 
// import { solaceRDP2Blob } from "./index";
// import { pathToFileURL } from "url";

// let sandbox: sinon.SinonSandbox;

interface AzureFunctionSettings {
    code: string,
    host: string,
    port: number,
    route: string
}
interface AzureStorageSettings {
    connection_string: string,
    container_name: string,
    path_prefix: string
}
interface AzureIntegrationSettings {
    function: AzureFunctionSettings,
    storage: AzureStorageSettings
}

interface AzureFunctionCallPayload {
    meta: {
        topic?: string,
        timestamp: string
    },
    body: {
        metric_1: number,
        metric_2: number
    }
}

class AzureFunctionCall {
    private baseUri : string;
    private settings: AzureFunctionSettings;
    private static max_retries: number = 10;
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

function sleep(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}
async function streamToString(readableStream: NodeJS.ReadableStream) {
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
async function deleteContainerIfExists(containerClient: ContainerClient, do_wait: boolean = true) : Promise<boolean> {
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
        }
    } else {
        console.log(`[deleteContainer] - nothing to do`);
    }
    return true;
}
interface BlobCount {
    fileCount: number,
    dirCount: number
}
async function countBlobs(containerClient: ContainerClient) : Promise<BlobCount> {
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

describe('solace-rdp-2-blob: azure integration tests', () => {

    // let functionContextStub: Partial<Context>;  
    // const index = rewire('./index');
    // const appSettingStorageConnectionString = index.__get__("appSettingStorageConnectionString");
    // const appSettingStorageContainerName = index.__get__("appSettingStorageContainerName");
    // const appSettingStoragePathPrefix = index.__get__("appSettingStoragePathPrefix");

    let TEST_ENV = {
        WORKING_DIR: (process.env['WORKING_DIR'] === undefined) ? null : process.env['WORKING_DIR'],
        SOLACE_INTEGRATION_PROJECT_HOME: (process.env['SOLACE_INTEGRATION_PROJECT_HOME'] === undefined) ? null : process.env['SOLACE_INTEGRATION_PROJECT_HOME'],
        SCRIPT_NAME: path.basename(__filename),
        INTEGRATION_SETTINGS_FILE: null as string,
        FUNCTION_NAME: 'solace-rdp-2-blob'
    } 
    let integrationSettings: object = null;
    let azureIntegrationSettings: AzureIntegrationSettings = null;
    let blobServiceClient: BlobServiceClient = null;
    let containerClient: ContainerClient = null;
    let azureFunctionCall: AzureFunctionCall = null;

    before("initializing test", async()=>{
        console.log('>>> initializing ...');

        if (TEST_ENV.SOLACE_INTEGRATION_PROJECT_HOME == null) {
            throw new Error(`>>> ERROR: ${TEST_ENV.SCRIPT_NAME} - missing env var: SOLACE_INTEGRATION_PROJECT_HOME`);
        }
        if (TEST_ENV.WORKING_DIR == null) {
            TEST_ENV.WORKING_DIR = TEST_ENV.SOLACE_INTEGRATION_PROJECT_HOME + "/tmp";
        }
        TEST_ENV.INTEGRATION_SETTINGS_FILE = TEST_ENV.WORKING_DIR + "/integration.settings.json";
        // console.log(`>>> TEST_ENV = ${JSON.stringify(TEST_ENV, null, 2)}`)
        integrationSettings = require(TEST_ENV.INTEGRATION_SETTINGS_FILE);
        console.log(`>>> integrationSettings = ${JSON.stringify(integrationSettings, null, 2)}`)
        for (const [key, value] of Object.entries(integrationSettings)) {
            if (key == TEST_ENV.FUNCTION_NAME) {
                azureIntegrationSettings = value.azure;   
            }
        }
        // console.log(`>>> azureIntegrationSettings = ${JSON.stringify(azureIntegrationSettings, null, 2)}`)
        // initialize globally
        azureFunctionCall = new AzureFunctionCall(azureIntegrationSettings);
        // initialize the blob/container client
        try {
            blobServiceClient = BlobServiceClient.fromConnectionString(azureIntegrationSettings.storage.connection_string);
            containerClient = blobServiceClient.getContainerClient(azureIntegrationSettings.storage.container_name);
        } catch (err) {
            throw new Error(`>>> ERROR: ${TEST_ENV.SCRIPT_NAME} - blob/container client: ${err.message}`);
        }
        // // start 
        // let success: boolean = await deleteContainer(containerClient);
    });
    after("teardown test", async()=>{
        console.log('>>> teardown ...');
        await deleteContainerIfExists(containerClient, false);
    });

    context("solace-rdp-2-blob: integration", ()=>{

        it("should create container", async()=>{
            await deleteContainerIfExists(containerClient);

            let topic = AzureFunctionCall.topic_1;
            let query_params: Array<string> = [`path=${topic}`]
            const response: Response = await azureFunctionCall.postMessage(query_params, azureFunctionCall.generatePayload(topic));
            expect(response.status, "error creating container & storing 1 message").to.equal(200);

            let containerExists = await containerClient.exists();
            expect(containerExists, "container does not exist, but it should now").to.be.true;

            let blobCount: BlobCount = await countBlobs(containerClient);
            expect(blobCount.fileCount, "fileCount is not equal 1").to.equal(1);
        }).timeout(180000);

        it("handle container marked for deletion by external process", async()=>{
            // ensure container exists
            const containerCreateIfNotExistsResponse = await containerClient.createIfNotExists();
            // console.log(`containerCreateIfNotExistsResponse=${JSON.stringify(containerCreateIfNotExistsResponse, null, 2)}`);
            // mark container for deletion, don't wait
            await deleteContainerIfExists(containerClient, false);
            // send message until good
            let topic = AzureFunctionCall.topic_1;  
            let query_params: Array<string> = [`path=${topic}`]
            const response: Response = await azureFunctionCall.postMessage(query_params, azureFunctionCall.generatePayload(topic));
            expect(response.status, "error creating container & storing 1 message").to.equal(200);

            let containerExists = await containerClient.exists();
            expect(containerExists, "container does not exist, but it should now").to.be.true;

            let blobCount: BlobCount = await countBlobs(containerClient);
            expect(blobCount.fileCount, "fileCount is not equal 1").to.equal(1);
        }).timeout(180000);

        it("fail by design", async()=>{
            let success = false;
            expect(success, "testing runner integration").to.be.true;
        });
        // it("should handle invalid container name", async()=>{
        //     let exists = await containerClient.exists();
        //     expect(exists, "container must exist for this test to work, but it doesn't").to.be.true;
        //     const invalid_names: string[] = ["InvalidContainerName", "%_-abc12", "-_abc$$12"];
        //     let i = 0;
        //     for (let name of invalid_names) {
        //         i++;
        //         process.env[appSettingStorageContainerName] = name;
        //         await solaceRDP2Blob(<Context>functionContextStub, request);
        //         expect(functionContextStub.log.error).to.have.callCount(i*2);
        //         expect(functionContextStub.log.error).to.have.been.calledWithMatch("ConfigError: The specifed resource name contains invalid characters");
        //         expect(functionContextStub.log.error).to.have.been.calledWithMatch(`${name}`);
        //     }
        // });
        
        // it("should upload blobs", async()=>{
        //     let containerClient:ContainerClient = null;
        //     process.env[appSettingStorageContainerName] = "mochauploadtest";
        //     containerClient = blobServiceClient.getContainerClient(process.env[appSettingStorageContainerName]);
        //     try { 
        //         let exists = await containerClient.exists();
        //         expect(exists, `test container must not exist but it does, name=${process.env[appSettingStorageContainerName]}`).to.be.false;
        //         await solaceRDP2Blob(<Context>functionContextStub, request);
        //         expect(functionContextStub.res.status).to.equal(400);
        //         exists = await containerClient.exists();
        //         expect(exists, `new test container not created, name=${process.env[appSettingStorageContainerName]}`).to.be.true;
        //         const numBlobs = 10;
        //         for(let i = 0; i < numBlobs; i++) {
        //             const request = {
        //                 query: { path: "p1/p2" },
        //                 rawBody: `content_number_${i}`
        //             };
        //             await solaceRDP2Blob(<Context>functionContextStub, request);
        //             expect(functionContextStub.res.status).to.equal(200);
        //         };

        //         let i = 0;
        //         for await(const response of containerClient.listBlobsFlat().byPage({ maxPageSize: numBlobs*2 })) {
        //             for(const blob of response.segment.blobItems) {
        //                 // console.log(`   >> properties: ${JSON.stringify(blob.properties)}`);
        //                 if(blob.properties.contentLength > 0) {
        //                     // console.log(`>>>> blob name ${i++}: ${blob.name}`);
        //                     let blobClient = new BlockBlobClient(process.env[appSettingStorageConnectionString], process.env[appSettingStorageContainerName], blob.name);
        //                     // console.log(`>>>>> dowloading ...`)
        //                     const downloadBlockBlobResponse = await blobClient.download();
        //                     // console.log(`>>>> stream to string ...`)
        //                     const download = await streamToString(downloadBlockBlobResponse.readableStreamBody);
        //                     // console.log(`     >>>> blob content: ${download}`);
        //                     expect(download).to.contain("content_number_");
        //                 } else {
        //                     // console.log(`>>>> path name: ${blob.name}`);
        //                 }
        //             }
        //         }

        //         await containerClient.delete();

        //     } catch(err) {
        //         // make sure container is deleted again 
        //         await containerClient.delete();
        //         console.log(`err = ${err}, details = ${JSON.stringify(err.details, null, 2)}`);
        //         expect(err.message).to.be.empty;
        //     }

        // });

    });
});