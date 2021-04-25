import * as path from 'path';

import { runTests } from 'vscode-test';

async function main() {
	try {
		const packageRootPath = path.resolve(__dirname, '../../');

		// The folder containing the Extension Manifest package.json
		// Passed to `--extensionDevelopmentPath`
		const extensionDevelopmentPath = packageRootPath;

		// The path to test runner
		// Passed to --extensionTestsPath
		const extensionTestsPath = path.resolve(__dirname, './suite');

		const extensionTestsEnv = {
			"YODA_EXECUTABLE_PATH": path.resolve(packageRootPath, '../../exe/yoda'),
			"YODA_DEBUG": "true",
		}

		// Download VS Code, unzip it and run the integration test
		await runTests({ extensionDevelopmentPath, extensionTestsPath, extensionTestsEnv });
	} catch (err) {
		console.error('Failed to run tests');
		process.exit(1);
	}
}

main();
