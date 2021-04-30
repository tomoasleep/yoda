'use strict';

import * as path from 'path';

// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import { workspace, ExtensionContext, OutputChannel, window, Disposable } from 'vscode';
import { LanguageClient, LanguageClientOptions, ServerOptions, TransportKind } from 'vscode-languageclient/node';
import { worker } from 'cluster';

let disposable: Disposable

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: ExtensionContext) {
    // Use the console to output diagnostic information (console.log) and errors (console.error)
    // This line of code will only be executed once when your extension is activated
    console.log('Congratulations, your extension "yoda" is now active!');

    const yodaPathEnv = process.env.YODA_EXECUTABLE_PATH

    const yodaPathConfiguration = workspace.getConfiguration("yoda").get("path") as (string | null);
    const yodaTraceConfiguration = workspace.getConfiguration("yoda").get("trace.server") as (string | null);

    const isDebug = !!(process.env.YODA_DEBUG?.length)
    const isTrace = isDebug || (yodaTraceConfiguration == "verbose")

    const command = yodaPathEnv || yodaPathConfiguration || 'yoda'
    console.log(`Use yoda at ${command}`)

    const logLevelOption = isTrace ? '--log-level=trace' : '--log-level=info'
    const serverOptions : ServerOptions = {
        run: { command, args: ['server', logLevelOption] },
        debug: { command, args: ['server', logLevelOption] },
    }

    const clientOptions : LanguageClientOptions = {
        documentSelector: [{ scheme: 'file', language: 'ruby' }],
        synchronize: {
            configurationSection: 'yoda',
            fileEvents: workspace.createFileSystemWatcher('**/.rb'),
        },
    }

    if (isDebug) {
        const outputChannel = window.createOutputChannel('yoda')
        const logOutputChannel: OutputChannel = {
            name: 'log',
            append(value: string) {
                outputChannel.append(value);
                console.log(value);
            },
            appendLine(value: string) {
                outputChannel.appendLine(value);
                console.log(value);
            },
            clear() { outputChannel.clear() },
            show() { outputChannel.show() },
            hide() { outputChannel.hide() },
            dispose() { outputChannel.dispose() }
        };

        clientOptions.outputChannel = logOutputChannel;
        clientOptions.traceOutputChannel = logOutputChannel;
    }

    disposable = new LanguageClient('yoda', 'Yoda', serverOptions, clientOptions).start();
}

// this method is called when your extension is deactivated
export function deactivate() {
    disposable?.dispose()
}
