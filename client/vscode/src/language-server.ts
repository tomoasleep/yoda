import { workspace, OutputChannel, window } from 'vscode'
import { LanguageClient, LanguageClientOptions, ServerOptions } from 'vscode-languageclient/node'
import { calcExecutionConfiguration, getTraceConfiguration } from './config'
import { outputChannel } from './status'

export function configureLanguageServer(): LanguageClient {
    const { command } = calcExecutionConfiguration()
    const yodaTraceConfiguration = getTraceConfiguration()

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

        clientOptions.outputChannel = logOutputChannel
        clientOptions.traceOutputChannel = logOutputChannel
    } else {
        clientOptions.outputChannel = outputChannel
    }

    return new LanguageClient('yoda', 'Yoda', serverOptions, clientOptions);
}

