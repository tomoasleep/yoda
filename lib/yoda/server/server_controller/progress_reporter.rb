module Yoda
  class Server
    class ServerController
      class ProgressReporter
        # @param [String, Integer, nil]
        attr_reader :work_done_token

        # @param [String, Integer, nil]
        attr_reader :partial_result_token

        # @param [Notifier]
        attr_reader :notifier

        # @param [Array]
        attr_reader :results

        class << self
          # @param work_done_token [String]
          # @param title [String]
          # @yield [reporter]
          # @yieldparam reporter [ProgressReporter]
          def in_workdone_progress(work_done_token:, title:, notifier:, &block)
            in_partial_result_progress(
              work_done_token: work_done_token,
              partial_result_token: nil,
              notifier: notifier,
              title: title,
              &block
            )
          end

          # @param work_done_token [String]
          # @param partial_result_token [String, nil]
          # @param title [String]
          # @yield [reporter]
          # @yieldparam reporter [ProgressReporter]
          def in_partial_result_progress(work_done_token:, partial_result_token:, notifier:, title:)
            reporter = ProgressReporter.new(
              work_done_token: work_done_token,
              partial_result_token: partial_result_token,
              notifier: notifier,
            )

            reporter.send_begin(title: title)
            yield reporter

            reporter.results
          ensure
            reporter.send_end
          end
        end

        # @param work_done_token [String, Integer, nil]
        # @param partial_result_token [String, Integer, nil]
        # @param notifier [Notifier]
        def initialize(work_done_token:, partial_result_token:, notifier:)
          @work_done_token = work_done_token
          @partial_result_token = partial_result_token
          @notifier = notifier
          @results = []
        end

        def send_begin(**kwargs)
          if work_done_token
            notifier.work_done_progress_begin(token: work_done_token, **kwargs)
          end
        end

        def send_end(**kwargs)
          if work_done_token
            notifier.work_done_progress_end(token: work_done_token, **kwargs)
          end
        end

        def report(**kwargs)
          if work_done_token
            notifier.work_done_progress_report(token: work_done_token, **kwargs)
          end
        end

        def send_result(value)
          if partial_result_token
            notifier.partial_result(token: partial_result_token, value: value)
          else
            results.push(value)
          end
        end
      end
    end
  end
end
