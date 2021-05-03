module Yoda
  module Model
    class Environment
      module WithCache
        # @param with_cache [Symbol]
        def with_cache(cache_name)
          cache_key = :"@#{cache_name}"
          return instance_variable_get(cache_key) if instance_variable_defined?(cache_key)
          instance_variable_set(cache_key, yield)
        end
      end
    end
  end
end
