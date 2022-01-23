require 'tmpdir'

module TmpdirHelper
  def self.included(mod_or_class)
    mod_or_class.module_eval do
      attr_reader :tmpdir

      around do |example|
        Dir.mktmpdir("rspec-") do |dir|
          @tmpdir = dir
          example.run
        end
      end
    end
  end
end
