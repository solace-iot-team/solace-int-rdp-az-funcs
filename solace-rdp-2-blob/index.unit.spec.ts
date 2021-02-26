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
import { BlockBlobClient, HttpRequestBody, BlockBlobUploadResponse, RestError, ContainerClient, ContainerCreateResponse } from "@azure/storage-blob";
import { solaceRDP2Blob } from "./index";

import * as fs from "fs";
import * as path from "path";
import { worker } from "cluster";

let sandbox: sinon.SinonSandbox;

describe('solace-rdp-2-blob: the function', () => {

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

    context("solace-rdp-2-blob: app settings & query params", ()=>{

        it("should validate app setting connection string", async()=>{
            const request = {};
            await solaceRDP2Blob(<Context>functionContextStub, request);
            expect(functionContextStub.log.info).to.have.callCount(4);
            expect(functionContextStub.log.error).to.have.been.calledOnce;
            expect(functionContextStub.log.error).to.have.been.calledWithMatch("ConfigError");
            expect(functionContextStub.log.error).to.have.been.calledWithMatch(appSettingStorageConnectionString);
            expect(functionContextStub.res.status).to.equal(400);
        });
        it("should validate app setting path prefix - missing", async()=>{
            process.env[appSettingStorageConnectionString] = "connection-string";
            process.env[appSettingStorageContainerName] = "container-name";
            delete process.env[appSettingStoragePathPrefix];
            const request = {
                query: { path: "path" }
            }
            await solaceRDP2Blob(<Context>functionContextStub, request);
            expect(functionContextStub.log.info).to.have.callCount(4);
            expect(functionContextStub.log.error).to.have.been.calledOnce;
            expect(functionContextStub.log.error).to.have.been.calledWithMatch("ConfigError");
            expect(functionContextStub.log.error).to.have.been.calledWithMatch(appSettingStoragePathPrefix);
            expect(functionContextStub.res.status).to.equal(400);
        });
        it("should validate app setting path prefix - empty", async()=>{
            process.env[appSettingStorageConnectionString] = "connection-string";
            process.env[appSettingStorageContainerName] = "container-name";
            process.env[appSettingStoragePathPrefix] = "";
            const request = {
                query: { path: "path" }
            }
            await solaceRDP2Blob(<Context>functionContextStub, request);
            expect(functionContextStub.log.error).to.have.been.calledOnce;
            expect(functionContextStub.log.error).to.have.been.calledWithMatch("ConfigError");
            expect(functionContextStub.log.error).to.have.been.calledWithMatch(appSettingStoragePathPrefix);
            expect(functionContextStub.log.error).to.have.been.calledWithMatch("is empty");
            expect(functionContextStub.res.status).to.equal(400);
        });
        it("should validate query param path", async()=>{
            process.env[appSettingStorageConnectionString] = "connection-string";
            process.env[appSettingStorageContainerName] = "container-name";
            process.env[appSettingStoragePathPrefix] = "path-prefix";
            const request = {
                query: { xpath: "path" }
            }
            await solaceRDP2Blob(<Context>functionContextStub, request);
            expect(functionContextStub.log.info).to.have.callCount(4);
            expect(functionContextStub.log.error).to.have.been.calledOnce;
            expect(functionContextStub.log.error).to.have.been.calledWithMatch("ConfigError");
            expect(functionContextStub.log.error).to.have.been.calledWithMatch("'path' not found");
            expect(functionContextStub.res.status).to.equal(400);
        });
        it("should validate query param pathCompose", async()=>{
            process.env[appSettingStorageConnectionString] = "connection-string";
            process.env[appSettingStorageContainerName] = "container-name";
            process.env[appSettingStoragePathPrefix] = "path-prefix";
            const request = {
                query: { path: "path", pathCompose: "invalid-choice" }
            }
            await solaceRDP2Blob(<Context>functionContextStub, request);
            expect(functionContextStub.log.info).to.have.callCount(4);
            expect(functionContextStub.log.error).to.have.been.calledOnce;
            expect(functionContextStub.log.error).to.have.been.calledWithMatch("ConfigError");
            expect(functionContextStub.log.error).to.have.been.calledWithMatch("'pathCompose' has invalid value of 'invalid-choice'");
            expect(functionContextStub.res.status).to.equal(400);
        });
        it("should catch invalid connection string value", async()=>{
            process.env[appSettingStorageConnectionString] = "connection-string";
            process.env[appSettingStorageContainerName] = "container-name";
            process.env[appSettingStoragePathPrefix] = "path-prefix";
            const request = {
                query: { path: "p1/p2/p3", pathCompose: "withTime" }
            }
            await solaceRDP2Blob(<Context>functionContextStub, request);
            expect(functionContextStub.log.info).to.have.callCount(6);
            expect(functionContextStub.log.error).to.have.been.calledOnce;
            expect(functionContextStub.log.error).to.have.been.calledWithMatch("ConfigError");
            expect(functionContextStub.log.error).to.have.been.calledWithMatch(`${appSettingStorageConnectionString}`);
            expect(functionContextStub.res.status).to.equal(400);
        });
        it("should discard empty content message", async()=>{
            process.env[appSettingStorageConnectionString] = "DefaultEndpointsProtocol=https;AccountName={accountName};AccountKey={accountKey};EndpointSuffix=core.windows.net";
            process.env[appSettingStorageContainerName] = "container-name";
            process.env[appSettingStoragePathPrefix] = "path-prefix";
            const request = {
                query: { path: "p1/p2/p3", pathCompose: "withTime" }
            }
            await solaceRDP2Blob(<Context>functionContextStub, request);
            expect(functionContextStub.log.info).to.have.callCount(6);
            expect(functionContextStub.log.warn).to.have.been.calledOnce;
            expect(functionContextStub.res.status).to.equal(200);
        });
        it("should catch invalid connection string value, URL composition", async()=>{
            let connectionString = "DefaultEndpointsProtocol=https;AccountName={accountName};AccountKey={accountKey};EndpointSuffix=core.windows.net";
            process.env[appSettingStorageConnectionString] = connectionString;
            process.env[appSettingStorageContainerName] = "container-name";
            process.env[appSettingStoragePathPrefix] = "path-prefix";
            const request = {
                query: { path: "p1/p2/p3", pathCompose: "withTime" },
                rawBody: "raw-body"
            }
            await solaceRDP2Blob(<Context>functionContextStub, request);
            expect(functionContextStub.log.info).to.have.callCount(6);
            expect(functionContextStub.log.error).to.have.been.calledTwice;
            expect(functionContextStub.res.status).to.equal(400);
        });
    });

    context("solace-rdp-2-blob: container", ()=>{

        it("should create container if not exist", async()=>{
            const uploadMock = (content: HttpRequestBody, contentLength: number): Promise<BlockBlobUploadResponse> => { 
                let restError = new RestError("message", "404", 404);
                restError.details={errorCode: "ContainerNotFound"};
                throw restError;
            } 
            let orgUpload = BlockBlobClient.prototype.upload;
            BlockBlobClient.prototype.upload = uploadMock;
            let orgCreate = ContainerClient.prototype.create;
            ContainerClient.prototype.create = sandbox.stub().resolves('fake_create');    
            let connectionString = "DefaultEndpointsProtocol=https;AccountName={accountName};AccountKey={accountKey};EndpointSuffix=core.windows.net";
            process.env[appSettingStorageConnectionString] = connectionString;
            process.env[appSettingStorageContainerName] = "container-name";
            process.env[appSettingStoragePathPrefix] = "path-prefix";
            const request = {
                query: { path: "p1/p2/p3", pathCompose: "withTime" },
                rawBody: "raw-body"
            }
            await solaceRDP2Blob(<Context>functionContextStub, request);
            expect(functionContextStub.log.info).to.have.callCount(7);
            expect(functionContextStub.res.status).to.equal(400);
            BlockBlobClient.prototype.upload = orgUpload;
            ContainerClient.prototype.create = orgCreate;
        });
        it("should add files to container", async()=>{
            let uploadStub = sandbox.stub().resolves('uploaded');
            let orgUpload = BlockBlobClient.prototype.upload;
            BlockBlobClient.prototype.upload = uploadStub;
            let connectionString = "DefaultEndpointsProtocol=https;AccountName={accountName};AccountKey={accountKey};EndpointSuffix=core.windows.net";
            process.env[appSettingStorageConnectionString] = connectionString;
            process.env[appSettingStorageContainerName] = "container-name";
            process.env[appSettingStoragePathPrefix] = "path-prefix";
            const request = {
                query: { path: "p1/p2/p3", pathCompose: "withTime" },
                rawBody: "raw-body"
            }
            await solaceRDP2Blob(<Context>functionContextStub, request);
            expect(uploadStub).to.have.been.calledOnce;
            expect(functionContextStub.res.status).to.equal(200);
            BlockBlobClient.prototype.upload = orgUpload;
        });

    });

    context("template.app.settings.json", ()=>{
        it("should check consistency with function expected settings", ()=>{
            let appSettingsTemplateFilename = path.join(__dirname, "/template.app.settings.json");
            let appSettingsTemplateBuffer = fs.readFileSync(appSettingsTemplateFilename);
            let appSettings = JSON.parse(appSettingsTemplateBuffer.toString());
            expect(appSettings).to.have.property(appSettingStorageConnectionString);
            expect(appSettings).to.have.property(appSettingStoragePathPrefix);
            expect(appSettings).to.have.property(appSettingStorageContainerName);
        });
    });

    context("template.local.settings.json", ()=>{
        it('should check consistency with function expected settings', ()=>{
            let localSettingsTemplateFilename = path.join(__dirname, "../template.local.settings.json");
            let localSettingsTemplateBuffer = fs.readFileSync(localSettingsTemplateFilename);
            let localSettings = JSON.parse(localSettingsTemplateBuffer.toString());
            let values = localSettings.Values;
            expect(values).to.have.property(appSettingStorageConnectionString);
            expect(values).to.have.property(appSettingStoragePathPrefix);
            expect(values).to.have.property(appSettingStorageContainerName);
        });
    });

});