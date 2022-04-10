module Yoda
  class Server
    module Providers
      module ReportableProgress
        # @param params [Hash] The parameter of the request
        def in_progress(params, title:, &block)
          server_controller.in_partial_result_progerss(
            title: title,
            work_done_token: params[:work_done_token],
            partial_result_token: params[:partial_result_token],
            &block
          )
        end
      end
    end
  end
end
