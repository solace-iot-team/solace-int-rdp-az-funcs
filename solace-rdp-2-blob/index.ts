
// Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
// All rights reserved.
// Licensed under the MIT License.

/*
TODO: TESTS
- local.settings.json 
    - config error --> error log?
        - invalid container name: "STORAGE_CONTAINER_NAME": "thisIsAnInvalidContainerName", solacerdptest
    - container does not exist --> created?

    Mocha & Chai, sinonjs for mocking and stubbing properties.
    https://adrianhall.github.io/web/2018/07/04/run-typescript-mocha-tests-in-vscode/

    https://github.com/Testy/TestyTs

TODO: FunctionArgs:
    - like Ansible: argSpec:
    type=string // always
    required=true/false,
    default=""
    options: ["a", "b"]
    ==> make pathCompose="None" the default
    Document (how) the function
    - perhaps add validation of container name?
        - https://docs.microsoft.com/en-us/rest/api/storageservices/naming-and-referencing-containers--blobs--and-metadata

TODO: Restructure:
    - project = app
    - multiple functions
    - package: just one function
        - needs local.settings.json per function.
    - solace-rdp-lib ==> just lib

*/


import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import { BlobServiceClient } from "@azure/storage-blob" 
import { generateUuid, RestError } from "@azure/core-http"
import { FunctionArgs } from "../solace-rdp-lib/FunctionArgs"
import { ConfigError } from "../solace-rdp-lib/Errors"

function composeBlobName(functionSettings: FunctionArgs, queryParams: FunctionArgs): string {

    if (queryParams.getArg('pathCompose') === 'withTime') {
        let timeStamp = new Date();
        let month: string = String(timeStamp.getUTCMonth() + 1).padStart(2, '0');
        let day: string = String(timeStamp.getUTCDate()).padStart(2, '0');
        let hours: string = String(timeStamp.getUTCHours() + 1).padStart(2, '0');
        let minutes: string = String(timeStamp.getUTCMinutes()).padStart(2, '0');
        let seconds: string = String(timeStamp.getUTCSeconds()).padStart(2, '0');
        return `${functionSettings.getArg('STORAGE_PATH_PREFIX')}/${queryParams.getArg('path')}/${timeStamp.getUTCFullYear()}/${month}/${day}/${hours}/${minutes}/${seconds}_${generateUuid()}`
    }
    return `${functionSettings.getArg('STORAGE_PATH_PREFIX')}/${queryParams.getArg('path')}/${generateUuid()}`
}

/**
 * https://www.npmjs.com/package/@azure/storage-blob
 * https://docs.microsoft.com/en-gb/javascript/api/@azure/storage-blob/?view=azure-node-latest
 * https://docs.microsoft.com/en-us/rest/api/storageservices/blob-service-error-codes
 * @param context 
 * @param req 
 */
const solaceRDP2Blob: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {

    context.log.info(`[INFO] - STARTING: ${context.executionContext.functionName} ...`);
    context.log.info(`[INFO] - req=${JSON.stringify(req, null, 2)}`);

    try {
        const settingKeys: string[] = ['STORAGE_PATH_PREFIX', 'STORAGE_CONNECTION_STRING', 'STORAGE_CONTAINER_NAME'];
        const functionSettings = new FunctionArgs('app-settings', process.env, settingKeys);
        const queryParamKeys: string[] = ['path', 'pathCompose'];
        const queryParams = new FunctionArgs('query-params', req.query, queryParamKeys);
        
        context.log.info(`[INFO] - settings=${functionSettings.toString()}`);
        context.log.info(`[INFO] - queryParams=${queryParams.toString()}`);

        const blobServiceClient = BlobServiceClient.fromConnectionString(functionSettings.getArg('STORAGE_CONNECTION_STRING'));
        const containerName = functionSettings.getArg('STORAGE_CONTAINER_NAME');
        const containerClient = blobServiceClient.getContainerClient(containerName);
        const blobName = composeBlobName(functionSettings, queryParams);
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
                    context.log.info(`[INFO] - container created: ${containerName}`);
                    // reject message ==> will receive message again    
                    context.res = { status: 400 };  
                    return;
                } else {
                    context.log.error(`[UPLOAD_FAILED] - uploading block blob failed: statusCode: ${err.statusCode}, details: ${JSON.stringify(err.details)}`);
                    if (err.statusCode === 400 && details.errorCode === 'InvalidResourceName') {                    
                        throw new ConfigError(`${details.message}\n(possible cause: invalid container name: '${containerName}')`);
                    }
                }
            } else throw err;
        }

        context.log.info(`[INFO] - upload block blob success: '${blobName}'`);

        context.res = { status: 200 }; 

    } catch(err) {
        if( ! (err instanceof ConfigError) ) { throw err; }
        context.log.error(`${err}`);        
        context.res = { status: 400 };    
    }

};

export default solaceRDP2Blob;

// The End.