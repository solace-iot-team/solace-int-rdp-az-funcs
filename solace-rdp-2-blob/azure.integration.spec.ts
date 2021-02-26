// Copyright (c) 2021, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
// All rights reserved.
// Licensed under the MIT License.

import "mocha";
import * as chai from "chai";
const expect = chai.expect;
import * as chaiAsPromised from "chai-as-promised";
chai.use(chaiAsPromised);
import * as sinonChai from "sinon-chai";
chai.use(sinonChai);
import path = require("path");

import { BlobServiceClient, ContainerClient } from "@azure/storage-blob" 
import { Response } from "node-fetch";
import { AzureFunctionCall, AzureIntegrationSettings, BlobCount, countBlobs, deleteContainerIfExists } from "../test-lib/test-lib"

describe('solace-rdp-2-blob: azure integration tests', () => {

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

    context("solace-rdp-2-blob: azure.integration", ()=>{

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
        });

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
        });

    });
});