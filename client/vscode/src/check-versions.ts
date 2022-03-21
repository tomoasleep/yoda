
import { execSync } from 'child_process'
import { cmp, maxSatisfying } from 'semver'
import { asyncExec } from './utils'

interface CheckResult {
    shouldUpdate: boolean
    localVersion: string
    remoteVersion: string
}

export async function checkVersions(): Promise<CheckResult> {
    const { stdout } = await asyncExec("gem list --both --exact yoda-language-server")
    const [localVersion, remoteVersion] = parseGemList(stdout)

    return {
        shouldUpdate: shouldUpdate(localVersion, remoteVersion),
        localVersion: localVersion,
        remoteVersion: remoteVersion,
    }
}

function shouldUpdate(localVersion: string, remoteVersion: string): boolean {
    if (!localVersion) {
        return true
    }

    if (!remoteVersion) {
        return false
    }

    return cmp(localVersion, "<", remoteVersion)
}

function parseGemList(stdout: string): [string, string] {
    const [local, remote] = stdout.split("*** REMOTE GEMS ***")

    const localVersion = extractVersion(local)
    const remoteVersion = extractVersion(remote)

    return [localVersion, remoteVersion]
}

function extractVersion(text: string): string {
    const lines = text.split("\n")
    for (const line of lines) {
        const matchData = line.match(/^yoda-language-server\s*\((.+)\)/);
        if (matchData) {
            const versions = matchData[1].split(/,\s*/)
            return maxSatisfying(versions, '*')
        }
    }

    return null
}
