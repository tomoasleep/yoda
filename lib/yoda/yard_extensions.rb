require 'yard'

module Yoda
  module YARDExtensions
    require 'yoda/yard_extensions/rbs_directive'
    require 'yoda/yard_extensions/rbs_exporter'

    YARD::Tags::Library.define_directive(:rbs, RbsDirective)
    YARD::Tags::Library.define_tag('Type', :type)
    YARD::Tags::Library.define_tag('RBS Signature', :rbs_signature)
  end
end
