module Yoda
  module Model
    # Each Value represents the result for symbolic execution.
    module Values
      require 'yoda/model/values/base'
      require 'yoda/model/values/empty_value'
      require 'yoda/model/values/instance_value'
      require 'yoda/model/values/intersection_value'
      require 'yoda/model/values/literal_value'
      require 'yoda/model/values/union_value'
    end
  end
end
