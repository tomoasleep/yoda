import * as vscode from 'vscode';
import * as assert from 'assert';
import { getDocUri, activate } from '../helper';

describe('Should provide hover', () => {
  const docUri = getDocUri('completion.rb');

  it('show hover', async () => {
    await testCompletion(docUri, new vscode.Position(0, 2), {
      contents: [
				{"language":"ruby","value":"Object # Object.module"},
				"**Object.class**\n\n\n",
			],
			range: new vscode.Range(
				new vscode.Position(0, 0),
				new vscode.Position(0, 6),
			),
    });
  })


});

async function testCompletion(
	docUri: vscode.Uri,
	position: vscode.Position,
	expectedHover: vscode.Hover
) {
	await activate(docUri);

	// Executing the command `vscode.executeCompletionItemProvider` to simulate triggering completion
	// See: https://code.visualstudio.com/api/references/commands
	const [actualHover] = await vscode.commands.executeCommand<vscode.Hover[]>(
		'vscode.executeHoverProvider',
		docUri,
		position
	);

	// assert.equal(actualHover.range, expectedHover.range);
	expectedHover.contents.forEach((expectedItem, i) => {
		assert.equal(actualHover.contents[i], expectedItem);
	});
}
