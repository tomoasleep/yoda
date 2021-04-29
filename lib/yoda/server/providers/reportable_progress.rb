module Yoda
  class Server
    module Providers
      module ReportableProgress
        # @param params [Hash] The parameter of the request
        def in_progress(params, title:)
          begin
            reporter = ProgressReporter.new(
              work_done_token: params[:work_done_token],
              partial_result_token: params[:partial_result_token],
              notifier: notifier,
            )

            reporter.send_begin(title: title)
            yield reporter

           reporter.results
          ensure
            reporter.send_end
          end
        end

        class ProgressReporter
          # @param [String, Integer, nil]
          attr_reader :work_done_token

          # @param [String, Integer, nil]
          attr_reader :partial_result_token

          # @param [Notifier]
          attr_reader :notifier

          # @param [Array]
          attr_reader :results

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
end
