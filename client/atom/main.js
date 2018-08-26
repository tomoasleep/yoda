const { AutoLanguageClient } = require('atom-languageclient')
const { spawn } = require('child_process')
const { resolve } = require('path')

class YodaClient extends AutoLanguageClient {
  constructor() {
    super()
  }

  preInitialization(connection) {
    connection.onTelemetryEvent(({ type, phase, message }) => {
      if (!this.busySignalService) { return; }
      if (type != 'initialization') { return; }

      if (this.initializationBusyMessage) {
        this.initializationBusyMessage.setTitle(message);
      } else {
        this.initializationBusyMessage = this.busySignalService.reportBusy(message);
      }
    });
  }

  postInitialization(_server) {
    if (this.initializationBusyMessage) {
      this.initializationBusyMessage.dispose();
      this.initializationBusyMessage = null;
    }
  }

  getGrammarScopes () { return ['source.ruby', 'source.rb', 'source.ruby.rails'] }
  getLanguageName () { return 'Ruby' }
  getServerName () { return 'Yoda' }
  getConnectionType() { return 'stdio' }

  getServerPath() {
    const serverPath = atom.config.get('yoda.serverPath');
    return (serverPath && serverPath.length) ? serverPath : 'yoda';
  }

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
    return spawn(this.getServerPath(), ['server'], commandOptions);
  }
}

module.exports = new YodaClient()
