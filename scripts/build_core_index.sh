#!/bin/sh

set -e

BASE_DIR=$(cd $(dirname $(dirname $0)) && pwd)
RUBY_VERSION=$(BUNDLE_GEMFILE=$BASE_DIR/Gemfile bundle exec ruby -e 'print RUBY_VERSION')

mkdir -p ~/.yoda/sources/
curl "https://cache.ruby-lang.org/pub/ruby/ruby-$RUBY_VERSION.tar.gz" > "/tmp/ruby-$RUBY_VERSION.tar.gz"
tar xvzf "/tmp/ruby-$RUBY_VERSION.tar.gz" -C ~/.yoda/sources > /dev/null

cd ~/.yoda/sources/ruby-$RUBY_VERSION
BUNDLE_GEMFILE=$BASE_DIR/Gemfile bundle exec yardoc -n *.c
BUNDLE_GEMFILE=$BASE_DIR/Gemfile bundle exec yardoc -b .yardoc-stdlib -o doc-stdlib -n

echo "Complete to build YARD indexes of the core library and standard libraries."
