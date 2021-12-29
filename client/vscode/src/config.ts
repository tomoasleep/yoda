import { workspace } from 'vscode'

export function calcExecutionConfiguration() {
    const yodaPathEnv = process.env.YODA_EXECUTABLE_PATH
    const yodaPathConfiguration = workspace.getConfiguration("yoda").get("path") as (string | null);
    const command = yodaPathEnv || yodaPathConfiguration || 'yoda'

    return { command }
}

export function getTraceConfiguration (): string | null {
  return workspace.getConfiguration("yoda").get("trace.server") as (string | null);
}
