// Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
// All rights reserved.
// Licensed under the MIT License.

import { ConfigError, InternalFunctionError } from "./Errors"

/**
 * Argument spec for a single argument.
 * Supports only string type arguments.
 * @export
 * @class ArgItem
 * @see {@link ArgSpec} 
 */
export class ArgItem {
    name: string;
    isRequired: boolean = true;
    defaultValue: string = null;
    choices: string[];
    type: string = "string";
    valueRegExpPattern: string;
    /**
     * Creates an instance of ArgItem.
     * @constructor
     * @memberof ArgItem
     * @param {string} name The name of the argument.
     * @param {boolean} [isRequired=true] Flag if argument is required.
     * @param {string} [defaultValue=null] Default value if not required.
     * @param {string[]} [choices=null] Array of valid values.
     * @see {@link ArgSpec} 
     * Usage:
     * ```js
     * argItem = new ArgItem("choiceSetting", true, null, ["choice1", "choice2"]);
     * ```
     */
    constructor(name: string, isRequired: boolean = true, defaultValue: string = null, choices: string[] = null, valueRegExpPattern: string = null) {
        this.name = name;
        this.isRequired = isRequired;
        this.defaultValue = defaultValue;
        this.choices = choices;
        this.valueRegExpPattern = valueRegExpPattern;
    }

    /**
     * Reg Exp: Alphanumeric characters, underscore.
     * ^ : start of string
     * [ : beginning of character group
     * a-z : any lowercase letter
     * A-Z : any uppercase letter
     * 0-9 : any digit
     * _ : underscore
     * ] : end of character group
     * * : zero or more of the given characters
     * $ : end of string
     */
    public static readonly alphaNumericUnderscoreRegExpPattern: string = "^[a-zA-Z0-9_]*$";

}
/**
 * Argument specification.
 * @type ArgSpec
 * @see {@link ArgItem}
 * @export
 * Usage:
 * ```js
 * const appSettingsSpec: ArgSpec = [
 *   new ArgItem("choiceSetting", true, null, ["choice1", "choice2"]),
 *   new ArgItem("appSettingStorageConnectionString"),
 *   new ArgItem("appSettingStoragePathPrefix"),
 * ]
 * ```
 */
export type ArgSpec = Array<ArgItem>;

/**
 * Manages function arguments from a given source, such 
 * as 'process.env' and 'req.query'. 
 * Facilitates error handling.
 *
 * @export
 * @class FunctionArgs
 * @see {@link ArgSpec}
 */
export class FunctionArgs {
    
    private args: {[k: string]: string} = {};
    private sourceName: string;

    /**
    * Creates an instance of FunctionArgs and validates the {source} against the {argSpec}.
    *
    * @constructor
    * @param {string} sourceName The user-friendly name of the argument source, such as 'app-settings' for process.env and 'query-params' for req.query. 
    * @param {Object.<string, string>} source The source map with key/value pairs.
    * @param {ArgSpec} argSpec The argument spec for argument keys expected to be found on {source}.
    * @memberof FunctionArgs
    * @throws {ConfigError} If a key is not found in the {source} or has an invalid value.
    * @throws {InternalFunctionError} if {argSpec} is empty
    *
    * Example using process.env:
    * ```js
    *    const appSettingStorageConnectionString: string = "Rdp2BlobStorageConnectionString";
    *    const appSettingStoragePathPrefix: string = "Rdp2BlobStoragePathPrefix";
    *    const appSettingStorageContainerName: string = "Rdp2BlobStorageContainerName";
    *    const appSettingsSpec: ArgSpec = [
    *        new ArgItem("choiceSetting", true, null, ["choice1", "choice2"]),
    *        new ArgItem(appSettingStorageConnectionString),
    *        new ArgItem(appSettingStoragePathPrefix),
    *        new ArgItem(appSettingStorageContainerName)
    *    ]
    *    const appSettings = new FunctionArgs('app-settings', process.env, appSettingsSpec);
    * ```
    */
    constructor(sourceName: string, source: {[k: string]: string}, argSpec: ArgSpec) {
        this.sourceName = sourceName;
        if (!argSpec || argSpec.length === 0) { throw new InternalFunctionError('no argSpec specified'); }
        for (let argItem of argSpec) {
            let key = argItem.name;
            let v = source[key];            
            if(v === undefined) {
                if(argItem.isRequired) { throw new ConfigError(`${sourceName} '${key}' not found. spec: ${JSON.stringify(argSpec)}`); }
                v = argItem.defaultValue;
            } else if(v==="") {
                if(argItem.isRequired) { throw new ConfigError(`${sourceName} '${key}' is empty. spec: ${JSON.stringify(argSpec)}`); }
                v = argItem.defaultValue;
            }
            if(argItem.choices !== null && argItem.choices.indexOf(v) === -1) { throw new ConfigError(`${sourceName} '${key}' has invalid value of '${v}'. choices: ${JSON.stringify(argItem.choices)}`); }
            if(argItem.valueRegExpPattern !== null) {
                const regExp = new RegExp(argItem.valueRegExpPattern);
                if(!regExp.test(v)) {
                    throw new ConfigError(`${sourceName} '${key}'='${v}' does not match regular expression: ${argItem.valueRegExpPattern}`);     
                }
            }
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
    public getValue(key: string) : string {
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