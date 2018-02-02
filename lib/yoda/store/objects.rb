module Yoda
  module Store
    module Objects
      VALUE_REGEXP = /\A[0-9a-z]/
      METHOD_PATTERN = /(.|#)(\w+)$/
      MODULE_TAIL_PATTERN = /(?:::(\w+)|^(\w+))$/

      class << self
      end

      require 'yoda/store/objects/base'
      require 'yoda/store/objects/namespace_object'
      require 'yoda/store/objects/class_object'
      require 'yoda/store/objects/value_object'
      require 'yoda/store/objects/document'
      require 'yoda/store/objects/meta_class_object'
      require 'yoda/store/objects/method_object'
      require 'yoda/store/objects/module_object'
      require 'yoda/store/objects/patch'
      require 'yoda/store/objects/patch_set'
      require 'yoda/store/objects/tag'
      require 'yoda/store/objects/tag_list'
      require 'yoda/store/objects/yard_importer'
    end
  end
end
