const { AutoLanguageClient } = require('atom-languageclient')

class YodaClient extends AutoLanguageClient {
  getGrammarScopes () { return [ 'source.ruby' ] }
  getLanguageName () { return 'Ruby' }
  getServerName () { return 'Yoda' }

  startServerProcess () {
    return super.spawnChildNode(['yoda', 'server'])
  }
}

module.exports = new CSharpLanguageClient()
