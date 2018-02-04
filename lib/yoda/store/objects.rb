module Yoda
  module Store
    module Objects
      VALUE_REGEXP = /\A[0-9a-z]/
      METHOD_PATTERN = /(.|#)(\w+)$/
      MODULE_TAIL_PATTERN = /(?:::(\w+)|^(\w+))$/

      require 'yoda/store/objects/base'
      require 'yoda/store/objects/namespace_object'
      require 'yoda/store/objects/class_object'
      require 'yoda/store/objects/value_object'
      require 'yoda/store/objects/document'
      require 'yoda/store/objects/overload'
      require 'yoda/store/objects/meta_class_object'
      require 'yoda/store/objects/method_object'
      require 'yoda/store/objects/module_object'
      require 'yoda/store/objects/patch'
      require 'yoda/store/objects/patch_set'
      require 'yoda/store/objects/tag'
      require 'yoda/store/objects/tag_list'

      class << self
        # @param hsh [Hash]
        # @param [Addressable, nil]
        def deserialize(hsh)
          case hsh[:type].to_sym
          when :class
            ClassObject.new(hsh)
          when :module
            ModuleObject.new(hsh)
          when :meta_class
            MetaClassObject.new(hsh)
          when :value
            ValueObject.new(hsh)
          when :method
            MethodObject.new(hsh)
          end
        end
      end
    end
  end
end
