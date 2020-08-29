// Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
// All rights reserved.
// Licensed under the MIT License.

export class ConfigError extends Error {
    
    constructor(...args: any[]) {
        super(...args) // 'Error' breaks prototype chain here
        Object.setPrototypeOf(this, new.target.prototype); // restore prototype chain
        // Maintains stack trace for where our error was thrown (only available on V8)
        if (Error.captureStackTrace) { Error.captureStackTrace(this, ConfigError); }  
        this.name = 'ConfigError';
    }
}

export class InternalFunctionError extends Error {
    
    constructor(...args: any[]) {
        super(...args) // 'Error' breaks prototype chain here
        Object.setPrototypeOf(this, new.target.prototype); // restore prototype chain
        // Maintains stack trace for where our error was thrown (only available on V8)
        if (Error.captureStackTrace) { Error.captureStackTrace(this, InternalFunctionError); }  
        this.name = 'InternalFunctionError';
    }
}

// The End.
