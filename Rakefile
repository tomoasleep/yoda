require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :vscode do
  desc "Build vscode extension"
  task :build do
    Dir.chdir(File.expand_path("./client/vscode", __dir__)) do
      sh "npm install"
      # See: https://code.visualstudio.com/api/working-with-extensions/publishing-extension
      sh "npx vsce package"
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
