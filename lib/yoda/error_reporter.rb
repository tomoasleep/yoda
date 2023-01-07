require 'yoda/instrument'

begin
  if ENV['YODA_SENTRY_DSN']
    require 'sentry-ruby'

    Sentry.init do |config|
      config.dsn = ENV['YODA_SENTRY_DSN']
      config.traces_sample_rate = 1.0
    end
  end
rescue LoadError
  # nop
end

module Yoda
  class ErrorReporter
    # @return [Yoda::ErrorReporter]
    def self.instance
      @instance ||= Yoda::ErrorReporter.new(defined?(Sentry) ? Sentry : nil)
    end

    # @return [#capture_exception, nil]
    attr_reader :reporter

    # @param reporter [#capture_exception, nil]
    def initialize(reporter)
      @reporter = reporter
    end

    # @param exception [Exception]
    def report(exception)
      reporter&.capture_exception(exception)
    end
  end
end
