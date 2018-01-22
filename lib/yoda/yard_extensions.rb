require 'yard'

module Yoda
  module YARDExtensions
    require 'yoda/yard_extensions/sig_directive'
    require 'yoda/yard_extensions/type_tag'

    YARD::Tags::Library.define_directive(:sig, SigDirective)
    YARD::Tags::Library.define_tag('Type', :type, TypeTag)
  end
end
