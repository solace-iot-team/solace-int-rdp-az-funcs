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
import path = require("path");

import { Context, Logger } from "@azure/functions";
import { BlobDownloadResponseModel, BlobServiceClient, BlockBlobClient, ContainerClient } from "@azure/storage-blob" 
import { solaceRDP2Blob } from "./index";
import { pathToFileURL } from "url";
import { AzureIntegrationSettings, BlobCount, countBlobs, deleteContainerIfExists, sleep } from "../test-lib/test-lib";

let sandbox: sinon.SinonSandbox;

describe('solace-rdp-2-blob: azure-container.integration', () => {

    let functionContextStub: Partial<Context>;  
    const index = rewire('./index');
    const appSettingStorageConnectionString = index.__get__("appSettingStorageConnectionString");
    const appSettingStorageContainerName = index.__get__("appSettingStorageContainerName");
    const appSettingStoragePathPrefix = index.__get__("appSettingStoragePathPrefix");

    let TEST_ENV = {
        WORKING_DIR: (process.env['WORKING_DIR'] === undefined) ? null : process.env['WORKING_DIR'],
        SOLACE_INTEGRATION_PROJECT_HOME: (process.env['SOLACE_INTEGRATION_PROJECT_HOME'] === undefined) ? null : process.env['SOLACE_INTEGRATION_PROJECT_HOME'],
        SCRIPT_NAME: path.basename(__filename),
        INTEGRATION_SETTINGS_FILE: null as string,
        FUNCTION_NAME: 'solace-rdp-2-blob',
        CONTAINER_NAME: "azcontainertest",
        PATH_PREFIX: "az-container-test-1/az-container-test-2"
    } 
    let integrationSettings: object = null;
    let azureIntegrationSettings: AzureIntegrationSettings = null;
    let blobServiceClient: BlobServiceClient = null;
    let containerClient: ContainerClient = null;

    before("initializing test", async()=>{
        console.log('>>> initializing ...');

        if (TEST_ENV.SOLACE_INTEGRATION_PROJECT_HOME == null) {
            throw new Error(`>>> ERROR: ${TEST_ENV.SCRIPT_NAME} - missing env var: SOLACE_INTEGRATION_PROJECT_HOME`);
        }
        if (TEST_ENV.WORKING_DIR == null) {
            TEST_ENV.WORKING_DIR = TEST_ENV.SOLACE_INTEGRATION_PROJECT_HOME + "/tmp";
        }
        TEST_ENV.INTEGRATION_SETTINGS_FILE = TEST_ENV.WORKING_DIR + "/integration.settings.json";
        integrationSettings = require(TEST_ENV.INTEGRATION_SETTINGS_FILE);
        for (const [key, value] of Object.entries(integrationSettings)) {
            if (key == TEST_ENV.FUNCTION_NAME) {
                azureIntegrationSettings = value.azure;   
            }
        }
        console.log(`>>> azureIntegrationSettings = ${JSON.stringify(azureIntegrationSettings, null, 2)}`)

        // initialize the blob/container client
        try {
            blobServiceClient = BlobServiceClient.fromConnectionString(azureIntegrationSettings.storage.connection_string);
            containerClient = blobServiceClient.getContainerClient(TEST_ENV.CONTAINER_NAME);
        } catch (err) {
            throw new Error(`>>> ERROR: ${TEST_ENV.SCRIPT_NAME} - blob/container client: ${err.message}`);
        }
    });
    after("teardown test", async()=>{
        console.log('>>> teardown ...');
        await deleteContainerIfExists(containerClient, false);
    });    
    beforeEach(()=>{
        sandbox = sinon.createSandbox();
        let loggerStub: Partial<Logger>;
        loggerStub = {
            info: sandbox.stub(),
            error: sandbox.stub(),
            warn: sandbox.stub(),
            // enable to see logging output
            // info: sandbox.stub().callsFake((...args)=>{ console.info(args); }),
            // Note: don't leave error with logging on, test analytis fails otherwise
            // error: sandbox.stub().callsFake((...args)=>{ console.error(args); }),
            // warn: sandbox.stub().callsFake((...args)=>{ console.warn(args); })
        }
        functionContextStub = {
            log: <Logger>loggerStub,
            executionContext: { functionName: "solaceRDP2Blob", invocationId: "123", functionDirectory: __dirname }
        };
        // set the env for the function
        process.env[appSettingStorageConnectionString] = azureIntegrationSettings.storage.connection_string;
        process.env[appSettingStorageContainerName] = TEST_ENV.CONTAINER_NAME;
        process.env[appSettingStoragePathPrefix] = TEST_ENV.PATH_PREFIX;
    });
    afterEach(()=>{
        sandbox.restore();
    });

    context("solace-rdp-2-blob: azure-container.integration", ()=>{

        it("testing test: should create container with 1 file", async()=>{
            await deleteContainerIfExists(containerClient);
            const request = {
                query: { path: "p1/p2" },
                rawBody: "azure-container.integration test"
            };
            let status = 400;
            let retries = 0;
            while(status != 200 && retries < 10) {
                console.log(`try number: ${retries}`)
                await solaceRDP2Blob(<Context>functionContextStub, request);
                // console.log(`functionContextStub = ${JSON.stringify(functionContextStub, null, 2)}`)
                status = functionContextStub.res.status;
                retries++;
                if (status != 200) await sleep(5000);
            }
            let blobCount: BlobCount = await countBlobs(containerClient);
            expect(blobCount.fileCount, "fileCount is not equal 1").to.equal(1);
        });

        it("should handle invalid container name setting", async()=>{
            const request = {
                query: { path: "p1/p2" },
                rawBody: "azure-container.integration test"
            };

            const invalidContainerNames: string[] = ["InvalidContainerName", "%_-abc12", "-_abc$$12"];
            let i = 0;
            for (let invalidContainerName of invalidContainerNames) {
                i++;
                process.env[appSettingStorageContainerName] = invalidContainerName;
                await solaceRDP2Blob(<Context>functionContextStub, request);
                expect(functionContextStub.log.error).to.have.callCount(i*2);
                expect(functionContextStub.log.error).to.have.been.calledWithMatch("ConfigError: The specifed resource name contains invalid characters");
                expect(functionContextStub.log.error).to.have.been.calledWithMatch(`${invalidContainerName}`);
            }
        });
        
        interface TestExpected {
            status: number,
            messages: string[]
        }
        interface TestConnectionStringExpected {
            connectionString: string,
            expected: TestExpected
        }

        it("should handle invalid connection string", async()=>{
            //  "connection_string": "DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=solacedatalake;AccountKey=6Ylan/wn0wu10wSmvWGmquSUzgxksolbXP5xLMfuEZmJRz2PoIKSDpqh1ywgjtMzDl8AionYpIWwpRyH47i/cg==",
            const request = {
                query: { path: "p1/p2" },
                rawBody: "azure-container.integration test"
            };
            const invalidConnectionStringTests: TestConnectionStringExpected[] = [
                {
                    connectionString: "no-account-name",
                    expected: {
                        status: 400,
                        messages: [
                            "ConfigError", 
                            "appSettings.Rdp2BlobStorageConnectionString",
                            "accountName"
                        ]
                    }
                },
                {
                    connectionString: "DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=xxx;AccountKey=xxx",
                    expected: {
                        status: 403,
                        messages: [
                            "RestError", 
                            "Server failed to authenticate"
                        ]
                    }
                },
                {
                    connectionString: `DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=${azureIntegrationSettings.storage.account_name};AccountKey=xxx`,
                    expected: {
                        status: 403,
                        messages: [
                            "RestError", 
                            "Server failed to authenticate"
                        ]
                    }
                }
            ]
            for (const invalidConnectionStringTest of invalidConnectionStringTests) {
                process.env[appSettingStorageConnectionString] = invalidConnectionStringTest.connectionString;
                await solaceRDP2Blob(<Context>functionContextStub, request);
                console.log(`functionContextStub = ${JSON.stringify(functionContextStub, null, 2)}`)
                expect(functionContextStub.res.status).to.be.equal(invalidConnectionStringTest.expected.status);
                for (const message of invalidConnectionStringTest.expected.messages) {
                    expect(functionContextStub.log.error).to.have.been.calledWithMatch(message); 
                }
            }
        });

        interface TestPathPrefixExpected {
            pathPrefix: string,
            expected: TestExpected
        }

        // Note: Azure Blob seems to be able to handle any path prefix
        // test disabled
        xit("should handle invalid path prefix", async()=>{
            const request = {
                query: { path: "p1/p2" },
                rawBody: "azure-container.integration test"
            };
            const invalidPathPrefixTests: TestPathPrefixExpected[] = [
                {
                    pathPrefix: "xx&*^%£@!",
                    expected: {
                        status: 400,
                        messages: [
                        ]
                    }
                }
            ]
            for (const invalidPathPrefixTest of invalidPathPrefixTests) {
                process.env[appSettingStoragePathPrefix] = invalidPathPrefixTest.pathPrefix;
                await solaceRDP2Blob(<Context>functionContextStub, request);
                console.log(`functionContextStub = ${JSON.stringify(functionContextStub, null, 2)}`)
                expect(functionContextStub.res.status).to.be.equal(invalidPathPrefixTest.expected.status);
                for (const message of invalidPathPrefixTest.expected.messages) {
                    expect(functionContextStub.log.error).to.have.been.calledWithMatch(message); 
                }
            }
        });

    });
});