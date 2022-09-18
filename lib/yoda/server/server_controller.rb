require 'forwardable'
require 'securerandom'

module Yoda
  class Server
    # A Facade class to call server's features.
    class ServerController
      require 'yoda/server/server_controller/capability'
      require 'yoda/server/server_controller/lock'
      require 'yoda/server/server_controller/progress_reporter'

      extend Forwardable

      # @return [ConcurrentWriter]
      attr_reader :writer

      # @return [Scheduler]
      attr_reader :scheduler

      # @return [ResponseCallbacks]
      attr_reader :response_callbacks

      # @return [Notifier]
      attr_reader :notifier

      # @return [Lock]
      attr_reader :request_lock

      # @return [Capability]
      attr_reader :capability

      # @param writer [ConcurrentWriter]
      # @param scheduler [Scheduler]
      def initialize(writer:, scheduler: Scheduler.new)
        @writer = writer
        @scheduler = scheduler
        @pending_requests = Concurrent::Array.new
        @response_callbacks = ResponseCallbacks.new
        @notifier = Notifier.new(writer)
        @request_lock = Lock.new(true)
        @capability = Capability.new
      end

      # @!method write_response(id:, result:)
      #   @param id [Object]
      #   @param result [Object]
      #   @return [void]
      delegate write_response: :notifier

      # @!method build_error_response(reason)
      #   @param reason [Exception, Symbol, Struct]
      #   @return [LanguageServer::Protocol::Interface::ResponseError]
      delegate build_error_response: :notifier

      # @return [void]
      def unlock_request!
        request_lock.unlock!
      end

      # @!method receive_client_capability(capability)
      #   @param capability [LanguageServer::Protocol::Interface::ClientCapabilities]
      delegate receive_client_capability: :capability

      # @param (see Notifier#write_request)
      # @return [void]
      def write_request(**kwargs)
        request_lock.request do
          notifier.write_request(**kwargs)
        end
      end

      # @param (see ProgressReporter.in_workdone_progress)
      def in_workdone_progress(**kwargs, &block)
        ProgressReporter.in_workdone_progress(**kwargs, notifier: notifier, &block)
      end

      # @param (see ProgressReporter.in_partial_result_progress)
      def in_partial_result_progress(**kwargs, &block)
        ProgressReporter.in_partial_result_progress(**kwargs, notifier: notifier, &block)
      end

      # @param title [String]
      # @yield [reporter]
      # @yieldparam reporter [ProgressReporter, nil]
      def in_new_workdone_progress(title:, &block)
        if capability.support_work_done_progress?
          work_done_token = make_id
          id = make_id

          response_callbacks.register_callback(id) do |response, error|
            Logger.debug("WorkDoneProgress: #{response} #{error}")
          end

          request_lock.request do
            notifier.create_work_done_progress(id: id, token: work_done_token)
            in_workdone_progress(work_done_token: work_done_token, title: title) do |reporter|
              block.call(reporter)
            end
          end
        else
          block.call
        end
      end

      # @param (see Scheduler#async)
      def async(id:, &block)
        scheduler.async(id: id, &block)
      end

      # @return [String]
      def make_id
        SecureRandom.uuid
      end
    end
  end
end
