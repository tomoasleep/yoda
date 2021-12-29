import { ExtensionContext, Disposable } from 'vscode'
import { isLanguageServerInstalled, promptForInstallTool } from './install-tools'
import { configureLanguageServer } from './language-server'

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

    const languageServer = configureLanguageServer()

    disposable = languageServer.start()
}

// this method is called when your extension is deactivated
export function deactivate() {
    disposable?.dispose()
}
