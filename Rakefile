require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :vscode do
  desc "Install dependencies of vscode extension"
  task :deps do
    Dir.chdir(File.expand_path("./client/vscode", __dir__)) do
      sh "npm install"
    end
  end

  desc "Build vscode extension"
  task build: :deps do
    Dir.chdir(File.expand_path("./client/vscode", __dir__)) do
      # See: https://code.visualstudio.com/api/working-with-extensions/publishing-extension
      sh "npx vsce package"
    end
  end

  desc "Test vscode extension"
  task test: :deps do
    Dir.chdir(File.expand_path("./client/vscode", __dir__)) do
      sh "npm test"
    end
  end

  desc "Install vscode extension"
  task install: :build do
    Dir.chdir(File.expand_path("./client/vscode", __dir__)) do
      # See: https://code.visualstudio.com/docs/editor/extension-marketplace#_install-from-a-vsix
      sh "code --install-extension yoda-*.vsix"
    end
  end
end
