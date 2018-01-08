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

  startServerProcess () {
    // const yoda = spawn('yoda', ['server']);
    const yoda = spawn(resolve(__dirname, '../../exe/yoda'), ['server']);
    yoda.stderr.on('data', (data) => {
      this.logger.warn(`${data}`);
    });
    yoda.on('close', (code) => {
      this.logger.debug(`child process exited with code ${code}`);
    });
    return yoda;
  }
}

module.exports = new YodaClient()
