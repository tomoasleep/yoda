# Yoda [![Build Status](https://travis-ci.org/tomoasleep/yoda.svg?branch=master)](https://travis-ci.org/tomoasleep/yoda)

Yoda is a Language Server (http://langserver.org/) for Ruby and provides autocompletion and code analysis (go-to-definition, code information, etc...).  

**Note: Yoda is alpha version. Please use with caution. Contributions are welcome!**

## Instation and Usage

## Getting Started

```bash
rake install # Install language server
rake vscode:install # Install vscode plugin
```

### Install language server

Yoda is hosted on RubyGems.

```
gem install yoda-language-server
```

See `Instation of Editor Plugin` section to install Yoda on your editor.


Yoda can be also used as a cli tool.

```
$ yoda setup # You must run this command first for your each project.
$ yoda infer path-to-your-code:line_num:char_num # Show information of the code at the specified position.
$ yoda complete <path-to-your-code>:<line-num>:<char-num> # Show completion at the specified position.
```

### Installation of Editor Plugin

#### Atom

```
apm install tomoasleep/yoda
```

### VSCode

```
rake vscode:install
```

#### Vim/NeoVim

Please use language server client such as [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim).
Here is a configuration example for LanguageClient-neovim.

```vim
let g:LanguageClient_serverCommands = {
    \ 'ruby': ['yoda', 'server'],
    \ }
```

#### Emacs

TBW

## Internal

### YARD utilization

Yoda figures structures of your source codes and library codes with YARD.  
Yoda intepret YARD tags such as `@return` tags and `@param` tags and infer code types from these information.

### Indexing

Yoda built index files for fast inference under `<your-project-dir>/.yoda` at startup.  
These index files contains structures of external sources (gems and standard libraries).  
Your project codes are parsed at startup but does not stored in indexes.

### Supporting Features

- autocompletion
  - [x] method completion
  - [x] constant completion
  - [x] (local, class, instance) variable completion
  - comment completion
    - [x] YARD tag completion
    - [x] YARD type literal completion
    - [x] parameter completion
- [x] jump to definition
- [x] hover
- [x] signature help
- [x] find references
- [x] workspace symbols
- [ ] diagnostics

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tomoasleep/yoda.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
