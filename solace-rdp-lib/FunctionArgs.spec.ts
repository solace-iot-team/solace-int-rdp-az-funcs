// Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
// All rights reserved.
// Licensed under the MIT License.

import 'mocha';
import { expect } from "chai";
import { FunctionArgs, ArgItem, ArgSpec } from "./FunctionArgs"
import { InternalFunctionError, ConfigError } from "./Errors";

describe('solace-rdp-lib: FunctionArgs', () => {
    context("Function arguments", ()=>{
        it("should throw exception for empty arg spec", ()=>{
            const argSpec: ArgSpec = [];    
            try {
                const args = new FunctionArgs('app-settings', process.env, argSpec);
                throw new Error("test failed");
            } catch(ex) {
                expect(ex).to.be.instanceOf(InternalFunctionError);
            }
        });
        it("should throw exception for arg not found", ()=>{
            const argSpec: ArgSpec = [new ArgItem("argDoesNotExist")];
            try {
                const args = new FunctionArgs('app-settings', process.env, argSpec);
                throw new Error("test failed");
            } catch(ex) {
                expect(ex).to.be.instanceOf(ConfigError);
            }
        });
        it("should throw exception for invalid choice value", ()=>{
            process.env['choiceArg'] = "invalid-choice-value";
            const argSpec: ArgSpec = [new ArgItem("choiceArg", true, null, ["choice1", "choice2"])];    
            try {
                const args = new FunctionArgs('app-settings', process.env, argSpec);
                throw new Error("test failed");
            } catch(ex) {
                expect(ex).to.be.instanceOf(ConfigError);
                expect(ex.message).to.have.string("app-settings 'choiceArg' has invalid value of 'invalid-choice-value'. choices:");
            }
        });
        it("should check correct arg value", ()=>{
            process.env["theArg"] = "theValue";
            const argSpec: ArgSpec = [new ArgItem("theArg")];    
            const args = new FunctionArgs('app-settings', process.env, argSpec);
            let v = args.getValue("theArg");
            expect(v).to.be.equal("theValue");
        });
        it("should check for empty arg value", ()=>{
            process.env["theArg"] = "";
            const argSpec: ArgSpec = [new ArgItem("theArg")];    
            try {
                const args = new FunctionArgs('app-settings', process.env, argSpec);
                throw new Error("test failed");
            } catch(ex) {
                expect(ex).to.be.instanceOf(ConfigError);
                expect(ex.message).to.have.string("'theArg' is empty");
            }
        });
        it("should check for wrong arg value based on reg exp", ()=>{
            const pattern: string = ArgItem.alphaNumericUnderscoreRegExpPattern;
            const wrong_values: string[] = ["%^%%", "abc12_-$", "%_-abc12", "-_abc$$12"];
            const correct_values: string[] = ["_abc123", "_", "_abcABC12__", "_abcABC12_abcABC12_"];
            const argName: string = "theArg";
            const argSpec: ArgSpec = [
                new ArgItem(argName, true, null, null, pattern)
            ];    
            for (let value of wrong_values) {
                process.env[argName] = value;
                try {
                    const args = new FunctionArgs('app-settings', process.env, argSpec);
                    throw new Error(`FAILED - did not catch wrong value - value='${value}', reg exp='${pattern}'`);
                } catch(ex) {
                    expect(ex).to.be.instanceOf(ConfigError);
                    expect(ex.message).to.have.string(`'${argName}'='${value}' does not match regular expression`);
                }    
            }
            for (let value of correct_values) {
                process.env[argName] = value;
                try {
                    const args = new FunctionArgs('app-settings', process.env, argSpec);
                    expect(args.getValue(argName)).to.equal(value);
                } catch(ex) {
                    throw new Error(`FAILED - correct value throws exception - value='${value}', reg exp='${pattern}'`);
                }    
            }
        });
    });
});