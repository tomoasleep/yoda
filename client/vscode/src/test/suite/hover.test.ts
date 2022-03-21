import * as vscode from 'vscode';
import { expect } from 'chai';
import { getDocUri, activate } from '../helper';

describe('Should provide hover', () => {
  const docUri = getDocUri('completion.rb');

  it('show hover', async () => {
		await activate(docUri);

		const actualHovers = await requestComplete(docUri, new vscode.Position(0, 2));

		console.log("hovers: ", actualHovers);

		expect((actualHovers[0].contents[0] as vscode.MarkdownString).value).to.include("Object # singleton(::Object)");
		expect((actualHovers[0].contents[1] as vscode.MarkdownString).value).to.include("**Object**")
  })
});

async function requestComplete(
	docUri: vscode.Uri,
	position: vscode.Position,
): Promise<vscode.Hover[]> {
	const hovers = await vscode.commands.executeCommand<vscode.Hover[]>(
		'vscode.executeHoverProvider',
		docUri,
		position,
	);

	return hovers
}
