module Yoda
  module Model
    module Descriptions
      class ValueDescription < Base
        # @return [Store::Objects::Base]
        attr_reader :value

        # @param value [Store::Objects::Base]
        def initialize(value)
          @value = value
        end

        # @return [String]
        def title
          "#{value.path}#{value.is_a?(Store::Objects::MetaClassObject) ? '.class' : ''}"
        end

        # @return [String]
        def sort_text
          value.name.to_s
        end

        def to_markdown
          <<~EOS
          **#{title}**

          #{value.document}
          EOS
        end
      end
    end
  end
end
