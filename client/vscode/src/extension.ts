'use strict';

import * as child_process from 'child_process'

// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import { workspace, ExtensionContext, OutputChannel, window, Disposable } from 'vscode'
import { LanguageClient, LanguageClientOptions, ServerOptions } from 'vscode-languageclient/node'
import { outputChannel } from './status';

let disposable: Disposable

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export async function activate(context: ExtensionContext) {
    // Use the console to output diagnostic information (console.log) and errors (console.error)
    // This line of code will only be executed once when your extension is activated
    // console.log('Congratulations, your extension "yoda" is now active!');

    if (!isLanguageServerInstalled()) {
        await promptForInstallTool()
    }

    const languageServer = configureLanguageServer();

    disposable = languageServer.start();
}

// this method is called when your extension is deactivated
export function deactivate() {
    disposable?.dispose()
}

function isLanguageServerInstalled(): boolean {
    const { command } =  calcExecutionConfiguration()
    try {
        child_process.execSync(command, { stdio: 'ignore' });
        return true
    } catch (e) {
        return false
    }
}

async function promptForInstallTool() {
    const choises = ['Install']
    const selected = await window.showInformationMessage('yoda command is not available. Please install.', ...choises)
    switch (selected) {
        case 'Install':
            installTool()
            break;
        default:
            break;
    }
}

function installTool() {
    outputChannel.show()
    outputChannel.clear()

    outputChannel.appendLine('Installing yoda...')

    try {
        child_process.execSync("gem list --installed --exact specific_install")
    } catch (e) {
        child_process.execSync("gem install specific_install")
    }

    child_process.execSync("gem specific_install tomoasleep/yoda")
    outputChannel.appendLine('yoda is installed.')
}

function calcExecutionConfiguration() {
    const yodaPathEnv = process.env.YODA_EXECUTABLE_PATH
    const yodaPathConfiguration = workspace.getConfiguration("yoda").get("path") as (string | null);
    const command = yodaPathEnv || yodaPathConfiguration || 'yoda'

    return { command }
}

function configureLanguageServer(): LanguageClient {
    const { command } = calcExecutionConfiguration();
    const yodaTraceConfiguration = workspace.getConfiguration("yoda").get("trace.server") as (string | null);

    const isDebug = !!(process.env.YODA_DEBUG?.length)
    const isTrace = isDebug || (yodaTraceConfiguration == "verbose")

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

    return new LanguageClient('yoda', 'Yoda', serverOptions, clientOptions);
}
