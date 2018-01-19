'use strict';

import * as path from 'path';

// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import { LanguageClient, LanguageClientOptions, ServerOptions, TransportKind } from 'vscode-languageclient';
import { worker } from 'cluster';
import { workspace } from 'vscode';

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
    // Use the console to output diagnostic information (console.log) and errors (console.error)
    // This line of code will only be executed once when your extension is activated
    console.log('Congratulations, your extension "yoda" is now active!');

    let execOptions = {
        command: path.resolve(__dirname, '../../../exe/yoda'),
        args: ['server'],
    }

    let serverOptions : ServerOptions = {
        run: execOptions,
        debug: execOptions,
    }

    let clientOptions : LanguageClientOptions = {
        documentSelector: [{ scheme: 'file', language: 'ruby' }],
        synchronize: {
            configurationSection: 'yoda',
            fileEvents: workspace.createFileSystemWatcher('**/.rb'),
        }
    }

    let disposable = new LanguageClient('yoda', 'Yoda Language Server', serverOptions, clientOptions).start();
}

// this method is called when your extension is deactivated
export function deactivate() {
}