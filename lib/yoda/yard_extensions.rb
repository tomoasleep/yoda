require 'yard'

module Yoda
  module YARDExtensions
    require_relative 'yard_extensions/rbs_directive'

    YARD::Tags::Library.define_directive(:rbs, RbsDirective)
    YARD::Tags::Library.define_tag('Type', :type)
    YARD::Tags::Library.define_tag('RBS Signature', :rbs_signature)
  end
end
