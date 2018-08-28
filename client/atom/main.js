const { AutoLanguageClient } = require('atom-languageclient')
const { spawn } = require('child_process')
const { resolve } = require('path')

const busyMessages = {
  text_document_hover: 'Preparing hover help',
  text_document_signature_help: 'Preparing signature help',
  text_document_completion: 'Completing',
  text_document_definition: 'Finding definition',
};

class YodaClient extends AutoLanguageClient {
  constructor() {
    super()
    this.busyHandlers = {};
  }

  preInitialization(connection) {
    connection.onTelemetryEvent((event) => this.handleTelemetryEvent(event));
  }

  postInitialization(_server) {
    if (this.busyHandlers.initialization) {
      this.busyHandlers.initialization.dispose();
      this.busyHandlers.initialization = null;
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

  handleTelemetryEvent(eventBody) {
    if (!this.busySignalService || !eventBody) { return; }
    switch (eventBody.type) {
      case 'initialization':
        return this.handleInitializationEvent(eventBody);
      case 'text_document_hover':
      case 'text_document_completion':
      case 'text_document_signature_help':
      case 'text_document_completion':
        return this.handleBusyEvent(eventBody.type, eventBody);
      default:
    }
  }

  handleInitializationEvent({ phase, message }) {
    if (this.busyHandlers.initialization) {
      this.busyHandlers.initialization.setTitle(message);
    } else {
      this.busyHandlers.initialization = this.busySignalService.reportBusy(message);
    }
  }

  handleBusyEvent(handlerName, { phase, message }) {
    switch (phase) {
      case 'begin':
        if (!this.busyHandlers[handlerName]) {
          this.busyHandlers[handlerName] = this.busySignalService.reportBusy("(Yoda) " + busyMessages[handlerName]);
        }
        break;
      case 'end':
        if (this.busyHandlers[handlerName]) {
          this.busyHandlers[handlerName].dispose();
          this.busyHandlers[handlerName] = null;
        }
        break;
    }
  }
}

module.exports = new YodaClient()
