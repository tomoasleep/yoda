const { AutoLanguageClient } = require('atom-languageclient')
const { spawn } = require('child_process')
const { resolve } = require('path')

class YodaClient extends AutoLanguageClient {
  constructor() {
    super()
    atom.config.set('core.debugLSP', true) // Debug the hell out of this
  }
  getGrammarScopes () { return ['source.ruby', 'source.rb', 'source.ruby.rails'] }
  getLanguageName () { return 'Ruby' }
  getServerName () { return 'Yoda' }
  getConnectionType() { return 'stdio' }

  startServerProcess (projectPath) {
    const yoda = this._launchYoda(projectPath);
    yoda.stderr.on('data', (data) => {
      this.logger.warn(`${data}`);
    });
    yoda.on('close', (code) => {
      this.logger.debug(`child process exited with code ${code}`);
    });
    return yoda;
  }

  _launchYoda(projectPath) {
    const commandOptions = { cwd: projectPath };
    const commandName = atom.inDevMode() ? resolve(__dirname, '../../exe/yoda') : 'yoda';
    return spawn(commandName, ['server'], commandOptions);
  }
}

module.exports = new YodaClient()
