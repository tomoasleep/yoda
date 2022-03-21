import { exec } from 'child_process'
import { promisify } from 'util'

function execPipeline(command: string, onMessage: (stdout: string | null, stderr: string | null) => void, callback: (error: Error) => void) {
    const process = exec(command, callback)
    process.stdout.on('data', (data) => onMessage(data.toString(), null))
    process.stderr.on('data', (data) => onMessage(null, data.toString()))
}

export const asyncExecPipeline = promisify(execPipeline)
export const asyncExec = promisify(exec)
