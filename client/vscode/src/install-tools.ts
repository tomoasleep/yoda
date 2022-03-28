import * as child_process from 'child_process'

import { window } from 'vscode'
import { checkVersions } from './check-versions'
import { calcExecutionConfiguration, getTraceConfiguration } from './config'
import { outputChannel } from './status'
import { asyncExec, asyncExecPipeline } from './utils'

export function isLanguageServerInstalled(): boolean {
    const { command } =  calcExecutionConfiguration()
    try {
        child_process.execSync(command, { stdio: 'ignore' });
        return true
    } catch (e) {
        return false
    }
}

export async function tryInstallOrUpdate() {
    try {
        if (!isLanguageServerInstalled()) {
            outputChannel.appendLine(`Yoda is not installed. Ask to install.`)
            await promptForInstallTool(false)
            return
        }

        const { shouldUpdate, localVersion, remoteVersion } = await checkVersions()

        console.log(`Local version: ${localVersion}`)
        console.log(`Available version: ${remoteVersion}`)
        console.log(`shouldUpdate: ${shouldUpdate}`)

        if (shouldUpdate) {
            await promptForInstallTool(localVersion !== null, remoteVersion)
        }
    } catch (e) {
        outputChannel.appendLine(`An error occured on update: ${e}`)
    }
}

export async function promptForInstallTool(update: boolean, newVersion?: string) {
    const choises = [update ? 'Update' : 'Install']

    const newVersionLabel = newVersion ? ` (${newVersion})` : ''

    const message = update ? 
    `A newer version of yoda${newVersionLabel} is available.` : 
    'yoda command is not available. Please install.'

    const selected = await window.showInformationMessage(message, ...choises)
    switch (selected) {
        case 'Install':
        case 'Update':
            await installTool()
            break;
        default:
            break;
    }
}

async function installTool() {
    outputChannel.show()
    outputChannel.clear()

    outputChannel.appendLine('Installing yoda...')

    await installGemFromRubygems()

    outputChannel.appendLine('yoda is installed.')
}

async function installGemFromRubygems() {
    outputChannel.appendLine('gem install yoda-language-server')
    await asyncExecPipeline("yes | gem install yoda-language-server", (stdout, stderr) => {
        if (stdout) {
            outputChannel.append(stdout)
        }
        if (stderr) {
            outputChannel.append(stderr)
        }
    })
}

async function installGemFromRepository() {
    try {
        await asyncExec("gem list --installed --exact specific_install")
    } catch (e) {
        outputChannel.appendLine('gem install specific_install')
        await asyncExecPipeline("gem install specific_install", (stdout, stderr) => {
            if (stdout) {
                outputChannel.append(stdout)
            }
            if (stderr) {
                outputChannel.append(stderr)
            }
        })
        outputChannel.appendLine('')
    }

    outputChannel.appendLine('gem specific_install tomoasleep/yoda')
    await asyncExecPipeline("gem specific_install tomoasleep/yoda", (stdout, stderr) => {
        if (stdout) {
            outputChannel.append(stdout)
        }
        if (stderr) {
            outputChannel.append(stderr)
        }
    })
}
