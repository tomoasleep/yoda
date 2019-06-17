require 'timeout'

module Yoda
  class Server
    module Providers
      module WithTimeout
        module PrependHook
          def provide(*args)
            begin
              Timeout.timeout(timeout) { super }
            rescue Timeout::Error => err
              if message = timeout_message(*args)
                Logger.error("Request expired: " + message)
              else
                Logger.error("Request expired")
              end
              raise err
            end
          end
        end

        def included(mod)
          mod.send(:prepend, PrependHook)
        end

        def timeout
          nil
        end

        def timeout_message(*args)
          nil
        end
      end
    end
  end
end
