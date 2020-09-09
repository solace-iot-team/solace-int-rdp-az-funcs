// Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
// All rights reserved.
// Licensed under the MIT License.

import { ConfigError, InternalFunctionError } from "./Errors"

// type is always string
export class ArgItem {
    name: string;
    isRequired: boolean = true;
    defaultValue: string = null;
    choices: string[];
    type: string = "string";
    constructor(name: string, isRequired: boolean = true, defaultValue: string = null, choices: string[] = null) {
        this.name = name;
        this.isRequired = isRequired;
        this.defaultValue = defaultValue;
        this.choices = choices;
    }
}
export type ArgSpec = Array<ArgItem>;

/**
 * Manages mandatory function arguments from a given source, such 
 * as 'process.env' and 'req.query'. 
 * Facilitates error handling.
 *
 * @export
 * @class FunctionArgs
 */
export class FunctionArgs {
    
    private args: {[k: string]: string} = {};
    private sourceName: string;

    /**
    * Creates an instance of FunctionArgs.
    *
    * @constructor
    * @param {string} sourceName The user-friendly name of the argument source, such as 'app-settings' for process.env and 'query-params' for req.query. 
    * @param {Object.<string, string>} source The source map with key/value pairs.
    * @param {string[]} argKeys Array of argument keys expected to be found on {source}.
    * @memberof FunctionArgs
    * @throws {ConfigError} If a key is not found in the {source}.
    * @throws {InternalFunctionError} if {argKeys} is empty
    *
    * Example using process.env:
    * ```js
    * const settingKeys: string[] = ['STORAGE_PATH_PREFIX', 'STORAGE_CONNECTION_STRING', 'STORAGE_CONTAINER_NAME'];
    * const functionSettings = new FunctionArgs('app-settings', process.env, settingKeys);
    * ```
    * Example using req.query:
    * ```js
    * const queryParamKeys: string[] = ['path', 'pathCompose'];
    * const queryParams = new FunctionArgs('query-params', req.query, queryParamKeys);
    * ```
    */
    // constructor(sourceName: string, source: {[k: string]: string}, argSpec: ArgSpec) {
    //     this.sourceName = sourceName;
    //     if (!argKeys || argKeys.length === 0) { throw new InternalFunctionError('no argKeys specified'); }
    //     for (let key of argKeys) {
    //         let v = source[key];
    //         if(v === undefined) { throw new ConfigError(`${sourceName} '${key}' not found. required: ${JSON.stringify(argKeys)}`); }
    //         this.args[key] = v;
    //     }        
    // }
    constructor(sourceName: string, source: {[k: string]: string}, argSpec: ArgSpec) {
        this.sourceName = sourceName;
        if (!argSpec || argSpec.length === 0) { throw new InternalFunctionError('no argSpec specified'); }
        for (let argItem of argSpec) {
            let key = argItem.name;
            let v = source[key];            
            if(v === undefined) {
                if(argItem.isRequired) { throw new ConfigError(`${sourceName} '${key}' not found. spec: ${JSON.stringify(argSpec)}`); }
                v = argItem.defaultValue;
            }
            if(argItem.choices !== null && argItem.choices.indexOf(v) === -1) { throw new ConfigError(`${sourceName} '${key}' has invalid value of '${v}'. choices: ${JSON.stringify(argItem.choices)}`); }
            this.args[key] = v;
        }        
    }

    /**
     * Returns the value for the key.
     * @param {string} key
     * @returns {string} the value 
     * @memberof FunctionArgs
     * @throws {InternalFunctionError} if key is not found.
     */
    public getArg(key: string) : string {
        let v = this.args[key];
        if(v === undefined) { throw new InternalFunctionError(`${this.sourceName}['${key}'] not found`); }
        return v;
    }
    /**
     * Returns a JSON string.
     * @returns {string} the instance as JSON.
     * @memberof FunctionArgs
     */
    public toString(): string {
        let j = {
            sourceName: this.sourceName, 
            source: this.args
        }
        return JSON.stringify(j);
    }
    
}

// The End.