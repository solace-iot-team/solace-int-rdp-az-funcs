
// Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
// All rights reserved.
// Licensed under the MIT License.

/*
TODO: TESTS
    - container does not exist --> created?

    Mocha & Chai, sinonjs for mocking and stubbing properties.
    https://adrianhall.github.io/web/2018/07/04/run-typescript-mocha-tests-in-vscode/

    https://github.com/Testy/TestyTs

*/


import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import { BlobServiceClient } from "@azure/storage-blob" 
import { generateUuid, RestError } from "@azure/core-http"
import { FunctionArgs, ArgItem, ArgSpec } from "../solace-rdp-lib/FunctionArgs"
import { ConfigError } from "../solace-rdp-lib/Errors"

function composeBlobName(appSettings: FunctionArgs, queryParams: FunctionArgs): string {

    if (queryParams.getValue(queryParamPathCompose) === pathComposeWithTime) {
        let timeStamp = new Date();
        let month: string = String(timeStamp.getUTCMonth() + 1).padStart(2, '0');
        let day: string = String(timeStamp.getUTCDate()).padStart(2, '0');
        let hours: string = String(timeStamp.getUTCHours() + 1).padStart(2, '0');
        let minutes: string = String(timeStamp.getUTCMinutes()).padStart(2, '0');
        let seconds: string = String(timeStamp.getUTCSeconds()).padStart(2, '0');
        return `${appSettings.getValue(appSettingStoragePathPrefix)}/${queryParams.getValue(queryParamPath)}/${timeStamp.getUTCFullYear()}/${month}/${day}/${hours}/${minutes}/${seconds}_${generateUuid()}`
    }
    return `${appSettings.getValue(appSettingStoragePathPrefix)}/${queryParams.getValue(queryParamPath)}/${generateUuid()}`
}

const appSettingStorageConnectionString: string = "Rdp2BlobStorageConnectionString";
const appSettingStoragePathPrefix: string = "Rdp2BlobStoragePathPrefix";
const appSettingStorageContainerName: string = "Rdp2BlobStorageContainerName";
const appSettingsSpec: ArgSpec = [
    new ArgItem(appSettingStorageConnectionString),
    new ArgItem(appSettingStoragePathPrefix),
    new ArgItem(appSettingStorageContainerName)
]
const queryParamPath: string = "path";
const queryParamPathCompose: string = "pathCompose";
const pathComposeWithTime: string = "withTime";
const queryParamsSpec: ArgSpec = [
    new ArgItem(queryParamPath, true, null, null, null),
    new ArgItem(queryParamPathCompose, false, "none", ["none", pathComposeWithTime])
]

/**
 * https://www.npmjs.com/package/@azure/storage-blob
 * https://docs.microsoft.com/en-gb/javascript/api/@azure/storage-blob/?view=azure-node-latest
 * https://docs.microsoft.com/en-us/rest/api/storageservices/blob-service-error-codes
 * @param context 
 * @param req 
 */
export const solaceRDP2Blob: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {

    context.log.info(`[INFO] - STARTING: ${context.executionContext.functionName} ...`);
    context.log.info(`[INFO] - req=${JSON.stringify(req, null, 2)}`);

    context.log.info(`[INFO] - appSettingsSpec=${JSON.stringify(appSettingsSpec)}`)
    context.log.info(`[INFO] - queryParamsSpec=${JSON.stringify(queryParamsSpec)}`)

    try {
        const appSettings = new FunctionArgs('app-settings', process.env, appSettingsSpec);
        const queryParams = new FunctionArgs('query-params', req.query, queryParamsSpec);
        context.log.info(`[INFO] - settings=${appSettings.toString()}`);
        context.log.info(`[INFO] - queryParams=${queryParams.toString()}`);

        let blobServiceClient: BlobServiceClient = null;
        try {
            blobServiceClient = BlobServiceClient.fromConnectionString(appSettings.getValue(appSettingStorageConnectionString));
        } catch (err) {
            throw new ConfigError(`'appSettings.${appSettingStorageConnectionString}': ${err.message}`);
        }
        const containerName = appSettings.getValue(appSettingStorageContainerName);
        const containerClient = blobServiceClient.getContainerClient(containerName);
        const blobName = composeBlobName(appSettings, queryParams);
        const blockBlobClient = containerClient.getBlockBlobClient(blobName);
        const content = req.rawBody;
        if ( content === undefined || content.length === 0) {
            context.log.warn(`[WARN] - message has no content, discarding.`);
            context.res = { status: 200 }; 
            return;
        }
        try {
            const uploadBlobResponse = await blockBlobClient.upload(content, content.length);
        } catch(err) {
            if(err instanceof RestError) {
                let details: any = err.details;
                if(err.statusCode === 404 && details.errorCode === 'ContainerNotFound') {
                    // create the container first
                    const createContainerResponse = await containerClient.create();
                    context.log.info(`[INFO] - container created. name:'${containerName}'`);
                    // reject message ==> will receive message again    
                    context.res = { status: 400 };  
                    return;
                } else {
                    context.log.error(`[ERROR] - uploading block blob failed: statusCode: ${err.statusCode}, details: ${JSON.stringify(err.details)}`);
                    if (err.statusCode === 400 && details.errorCode === 'InvalidResourceName') {                    
                        throw new ConfigError(`${details.message}\n(possible cause: invalid container name: '${containerName}')`);
                    } else {
                        throw err; // uknown RestError
                    }
                }
            } else if(err instanceof TypeError){
                context.log.error(`[ERROR] - uploading block blob failed: details: ${err.message}`);
                throw new ConfigError(`${err.message}\n(possible cause: invalid blob connection string: '${appSettings.getValue(appSettingStorageConnectionString)}')`);
            } else throw err;
        } 

        context.log.info(`[INFO] - upload block blob success: '${blobName}'`);

        context.res = { status: 200 }; 

    } catch(err) {
        let status = 400; // default: Bad Request
        if( err instanceof RestError) {
            status = err.statusCode;
        } else if( err instanceof ConfigError) { 
            status = 400; // any better code?
        }
        context.log.error(`[ERROR] - ${err}`);        
        context.res = { status: status };
    }

};

// The End.