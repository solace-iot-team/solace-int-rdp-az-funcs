// Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
// All rights reserved.
// Licensed under the MIT License.

import "mocha";
import * as chai from "chai";
const expect = chai.expect;
import * as chaiAsPromised from "chai-as-promised";
chai.use(chaiAsPromised);
import * as sinon from "sinon";
import * as sinonChai from "sinon-chai";
chai.use(sinonChai);
import rewire = require("rewire");

import { Context, Logger } from "@azure/functions";
import { BlobDownloadResponseModel, BlobServiceClient, BlockBlobClient, ContainerClient } from "@azure/storage-blob" 
import { solaceRDP2Blob } from "./index";

let sandbox: sinon.SinonSandbox;

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

describe('solace-rdp-2-blob: az container integration tests', () => {

    let functionContextStub: Partial<Context>;  
    const index = rewire('./index');
    const appSettingStorageConnectionString = index.__get__("appSettingStorageConnectionString");
    const appSettingStorageContainerName = index.__get__("appSettingStorageContainerName");
    const appSettingStoragePathPrefix = index.__get__("appSettingStoragePathPrefix");

    beforeEach(()=>{
        sandbox = sinon.createSandbox();
        let loggerStub: Partial<Logger>;
        loggerStub = {
            info: sandbox.stub(),
            error: sandbox.stub(),
            warn: sandbox.stub(),
            // enable to see logging output
            // info: sandbox.stub().callsFake((...args)=>{ console.info(args); }),
            // error: sandbox.stub().callsFake((...args)=>{ console.error(args); }),
            // warn: sandbox.stub().callsFake((...args)=>{ console.warn(args); })
        }
        functionContextStub = {
            log: <Logger>loggerStub,
            executionContext: { functionName: "solaceRDP2Blob", invocationId: "123", functionDirectory: __dirname }
        };
    });
    afterEach(()=>{
        sandbox.restore();
    });

    context("solace-rdp-2-blob: integration with az container", ()=>{

        // TODO: how to get the connection string?
        process.env[appSettingStorageConnectionString] = "DefaultEndpointsProtocol=https;AccountName=solaceintdl;AccountKey=64+Zer/eDahL2/oLjNnLOXpjS/nIJ7/PYjNguNxGHRZwl1RvRS7gwZC+sqYyDJZ9G9NfOqNT0LdBht/olzawAQ==;EndpointSuffix=core.windows.net";
        process.env[appSettingStorageContainerName] = "mocha";
        process.env[appSettingStoragePathPrefix] = "prefix";
        const request = {
            query: { path: "p1/p2" },
            rawBody: "raw-body"
        }
        let blobServiceClient: BlobServiceClient = null;
        let containerClient: ContainerClient = null;
        try {
            blobServiceClient = BlobServiceClient.fromConnectionString(process.env[appSettingStorageConnectionString]);
            containerClient = blobServiceClient.getContainerClient(process.env[appSettingStorageContainerName]);
        } catch (err) {
            throw new Error(`FAILED - blob/container client: ${err.message}`);
        }

        beforeEach(()=>{
            process.env[appSettingStorageConnectionString] = "DefaultEndpointsProtocol=https;AccountName=solaceintdl;AccountKey=64+Zer/eDahL2/oLjNnLOXpjS/nIJ7/PYjNguNxGHRZwl1RvRS7gwZC+sqYyDJZ9G9NfOqNT0LdBht/olzawAQ==;EndpointSuffix=core.windows.net";
            process.env[appSettingStorageContainerName] = "mocha";
            process.env[appSettingStoragePathPrefix] = "prefix";
        });
        afterEach(()=>{
            delete process.env[appSettingStorageConnectionString];
            delete process.env[appSettingStorageContainerName];
            delete process.env[appSettingStoragePathPrefix];
        });
        after(async()=>{
            const deleteContainerResponse = await containerClient.delete();
        });

        it("should create container when it doesn't exist", async()=>{
            let exists = await containerClient.exists();
            if(exists) {
                const deleteContainerResponse = await containerClient.delete();
                // deletion doesn't happen instantly but during garbage collection
                await sleep(60000);    
            }
            await solaceRDP2Blob(<Context>functionContextStub, request);
            expect(functionContextStub.res.status).to.be.oneOf([400]);
            exists = await containerClient.exists();
            expect(exists, "container does not exist").to.be.true;
        }).timeout(180000);

        it("should wait until container is deleted, then create it", async()=>{
            // mark container for deletion
            let blobServiceClient: BlobServiceClient = null;
            let containerClient: ContainerClient = null;
            try {
                blobServiceClient = BlobServiceClient.fromConnectionString(process.env[appSettingStorageConnectionString]);
                containerClient = blobServiceClient.getContainerClient(process.env[appSettingStorageContainerName]);
            } catch (err) {
                throw new Error(`FAILED - blob/container client: ${err.message}`);
            }
            let exists = await containerClient.exists();
            expect(exists, "container must exist for this test to work, but it doesn't").to.be.true;
            const deleteContainerResponse = await containerClient.delete();
            // deletion doesn't happen instantly but during garbage collection
            // function will return 409 and RDP will try again
            let i = 0;
            do {
                i++;
                // console.log(`>>>> try number = ${i}`);
                await solaceRDP2Blob(<Context>functionContextStub, request);
                if(functionContextStub.res.status !== 400) {
                    expect(functionContextStub.log.error).to.have.been.calledWithMatch("ContainerBeingDelete");
                    await sleep(10000);
                }
            } while ( functionContextStub.res.status === 409 && i < 10);
            // console.log(`>>>> number of retries = ${i-1}`);

            expect(functionContextStub.res.status).to.be.oneOf([400]);
            exists = await containerClient.exists();
            expect(exists, "container does not exist").to.be.true;
    
        }).timeout(180000);

        it("should handle invalid container name", async()=>{
            let exists = await containerClient.exists();
            expect(exists, "container must exist for this test to work, but it doesn't").to.be.true;
            const invalid_names: string[] = ["InvalidContainerName", "%_-abc12", "-_abc$$12"];
            let i = 0;
            for (let name of invalid_names) {
                i++;
                process.env[appSettingStorageContainerName] = name;
                await solaceRDP2Blob(<Context>functionContextStub, request);
                expect(functionContextStub.log.error).to.have.callCount(i*2);
                expect(functionContextStub.log.error).to.have.been.calledWithMatch("ConfigError: The specifed resource name contains invalid characters");
                expect(functionContextStub.log.error).to.have.been.calledWithMatch(`${name}`);
            }
        });
        
        it("should upload blobs", async()=>{
            let containerClient:ContainerClient = null;
            process.env[appSettingStorageContainerName] = "mochauploadtest";
            containerClient = blobServiceClient.getContainerClient(process.env[appSettingStorageContainerName]);
            try { 
                let exists = await containerClient.exists();
                expect(exists, `test container must not exist but it does, name=${process.env[appSettingStorageContainerName]}`).to.be.false;
                await solaceRDP2Blob(<Context>functionContextStub, request);
                expect(functionContextStub.res.status).to.equal(400);
                exists = await containerClient.exists();
                expect(exists, `new test container not created, name=${process.env[appSettingStorageContainerName]}`).to.be.true;
                const numBlobs = 10;
                for(let i = 0; i < numBlobs; i++) {
                    const request = {
                        query: { path: "p1/p2" },
                        rawBody: `content_number_${i}`
                    };
                    await solaceRDP2Blob(<Context>functionContextStub, request);
                    expect(functionContextStub.res.status).to.equal(200);
                };

                let i = 0;
                for await(const response of containerClient.listBlobsFlat().byPage({ maxPageSize: numBlobs*2 })) {
                    for(const blob of response.segment.blobItems) {
                        // console.log(`   >> properties: ${JSON.stringify(blob.properties)}`);
                        if(blob.properties.contentLength > 0) {
                            // console.log(`>>>> blob name ${i++}: ${blob.name}`);
                            let blobClient = new BlockBlobClient(process.env[appSettingStorageConnectionString], process.env[appSettingStorageContainerName], blob.name);
                            // console.log(`>>>>> dowloading ...`)
                            const downloadBlockBlobResponse = await blobClient.download();
                            // console.log(`>>>> stream to string ...`)
                            const download = await streamToString(downloadBlockBlobResponse.readableStreamBody);
                            // console.log(`     >>>> blob content: ${download}`);
                            expect(download).to.contain("content_number_");
                        } else {
                            // console.log(`>>>> path name: ${blob.name}`);
                        }
                    }
                }

                await containerClient.delete();

            } catch(err) {
                // make sure container is deleted again 
                await containerClient.delete();
                console.log(`err = ${err}, details = ${JSON.stringify(err.details, null, 2)}`);
                expect(err.message).to.be.empty;
            }

        });

    });
});