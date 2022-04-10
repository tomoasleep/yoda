module Yoda
  class Server
    class InitializationProgressReporter
      # @return [Providers::ReportableProgress::ProgressReporter]
      attr_reader :progress_reporter

      def self.wrap(progress_reporter, &block)
        reporter = InitializationProgressReporter.new(progress_reporter)

        subscriptions = {
          initialization_progress: reporter.public_method(:notify_initialization_progress),
          build_library_registry: reporter.public_method(:notify_build_library_registry),
        }

        Instrument.instance.hear(**subscriptions, &block)
      end

      # @param progress_reporter [Providers::ReportableProgress::ProgressReporter]
      def initialize(progress_reporter)
        @progress_reporter = progress_reporter
      end

      def notify_initialization_progress(phase: nil, message: nil, index:, length:)
        if length && length > 0
          percentage = (index || 0) * 100 / length

          progress_reporter.report(message: message, percentage: percentage)
        else
          progress_reporter.report(message: message)
        end

        progress_reporter.notifier.event(type: :initialization, phase: phase, message: message)
      end

      def notify_build_library_registry(message: nil, name: nil, version: nil)
        progress_reporter.report(message: message)
      end
    end
  end
end
