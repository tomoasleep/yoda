import * as child_process from 'child_process'

import { window } from 'vscode'
import { calcExecutionConfiguration, getTraceConfiguration } from './config'
import { outputChannel } from './status'
import { promisify } from 'util'

function execCommand(command: string, onMessage: (stdout: string | null, stderr: string | null) => void, callback: (error: Error) => void) {
    const process = child_process.exec(command, callback)
    process.stdout.on('data', (data) => onMessage(data.toString(), null))
    process.stderr.on('data', (data) => onMessage(null, data.toString()))
}

const asyncExecCommand = promisify(execCommand)

export function isLanguageServerInstalled(): boolean {
    const { command } =  calcExecutionConfiguration()
    try {
        child_process.execSync(command, { stdio: 'ignore' });
        return true
    } catch (e) {
        return false
    }
}

export async function promptForInstallTool() {
    const choises = ['Install']
    const selected = await window.showInformationMessage('yoda command is not available. Please install.', ...choises)
    switch (selected) {
        case 'Install':
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

    try {
        child_process.execSync("gem list --installed --exact specific_install")
    } catch (e) {
        outputChannel.appendLine('gem install specific_install')
        await asyncExecCommand("gem install specific_install", (stdout, stderr) => {
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
    await asyncExecCommand("gem specific_install tomoasleep/yoda", (stdout, stderr) => {
        if (stdout) {
            outputChannel.append(stdout)
        }
        if (stderr) {
            outputChannel.append(stderr)
        }
    })
    outputChannel.appendLine('yoda is installed.')
}
