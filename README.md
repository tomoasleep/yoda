# Yoda (In Progress) [![Build Status](https://travis-ci.org/tomoasleep/yoda.svg?branch=master)](https://travis-ci.org/tomoasleep/yoda)

Yoda is a static analytics tool for Ruby to provide autocompletion, go-to-definition, documentation on hover and so on.
Yoda is designed to provide these features for multiple editors by using language server protocol (https://microsoft.github.io/language-server-protocol/).

## Language Server

`yoda server` provides many features such as autocompletion and hovering datatips over language server protocol (https://microsoft.github.io/language-server-protocol/).

### Supporting Features

- autocompletion
  - [x] method completion
    - Supported in method bodies only
  - [ ] constant completion
  - [ ] (local, class, instance) variable completion
  - :small_red_triangle: comment completion
    - [x] YARD tag completion
    - [x] YARD type literal completion
    - [ ] parameter completion
- :small_red_triangle: jump to definition
  - Supported in method bodies only
- :small_red_triangle: hover
  - Supported in method bodies only
- :small_red_triangle: signature help
  - Supported in method bodies only
- [ ] find references
- [ ] workspace symbols
- [ ] diagnostics

## Internal

Yoda analyzes your program structure without executing your code by using ruby parser and YARD.
Yoda figures program structures of your dependencies from YARD index files and
figures one of your project codes by parsing your project codes.

Yoda internally uses YARD for program analysis so Yoda can understand type hints written in your comments such as `@return` tags and `@param` tags.
Yoda utilizes these type hints for completion features.

## Installation

### Install cli command

```
$ bundle exec rake install
$ ./scripts/build_core_index.sh # Download Ruby source code and build index of ruby core and stdlib.
```

You can infer the type of the specified code.

```
$ yoda setup # Build index for your project
$ yoda infer <YOUR_FILE_TO_INSPECT>:<LINE_NUMBER>:<COLUMN_NUMBER> 
```

### Install Atom Package

This repository contains an Atom package to use Yoda.
(This package is alpha version and it has many bugs.)

This package requires cli

```
$ ./bin/setup
$ apm link
```


## Usage

TBW

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tomoasleep/yoda.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
