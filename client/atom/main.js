const { AutoLanguageClient } = require('atom-languageclient')
const { spawn } = require('child_process')
const { resolve } = require('path')

const busyMessages = {
  'textDocument/hover': 'Preparing hover help',
  'textDocument/signatureHelp': 'Preparing signature help',
  'textDocument/completion': 'Completing',
  'textDocument/definition': 'Finding definition',
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
      case 'textDocument/hover':
      case 'textDocument/completion':
      case 'textDocument/signatureHelp':
      case 'textDocument/completion':
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

  handleBusyEvent(handlerName, { phase, id }) {
    switch (phase) {
      case 'begin':
        if (!this.busyHandlers[handlerName]) {
          this.busyHandlers[handlerName] = {
            handler: this.busySignalService.reportBusy("(Yoda) " + (busyMessages[handlerName] || 'Processing')),
            ids: new Set([]),
          };
          if (id) { this.busyHandlers[handlerName].ids.add(id); }
        }
        break;
      case 'end':
        if (this.busyHandlers[handlerName]) {
          if (id) { this.busyHandlers[handlerName].ids.delete(id); }
          if (!this.busyHandlers[handlerName].ids.size) {
            this.busyHandlers[handlerName].handler.dispose();
            this.busyHandlers[handlerName] = null;
          }
        }
        break;
    }
  }
}

module.exports = new YodaClient()
