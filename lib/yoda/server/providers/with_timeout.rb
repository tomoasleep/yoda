require 'timeout'

module Yoda
  class Server
    module Providers
      module WithTimeout
        module PrependHook
          def provide(*args)
            Timeout.timeout(timeout) { super }
          end
        end

        def included(mod)
          mod.send(:prepend, PrependHook)
        end

        def timeout
          nil
        end
      end
    end
  end
end
