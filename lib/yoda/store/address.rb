module Yoda
  module Store
    class Address
      CONSTANT_SEPARATOR = '::'.freeze
      SEPARATOR_PATTERN = /[#.]|(::)/

      # @return [String]
      attr_reader :content

      # @param content [String]
      def initialize(content:)
        @content = content.to_s
      end

      # @return [Symbol]
      def to_sym
        content.to_sym
      end

      # @return [String]
      def to_s
        content
      end

      # @param (see #eql?)
      # @return [Boolean]
      def ==(another)
        content == Address.of(another).content
      end

      # @param another [#to_s]
      # @return [Boolean]
      def eql?(another)
        another.is_a?(Address) && content == another.content
      end

      def hash
        [self.class, content].hash
      end

      def <=>(another)
        self.content <=> Address.of(another).content
      end

      # @return [Address]
      def namespace
        Address.of(divide_by_separator[0])
      end

      # @return [String]
      def name
        divide_by_separator[2]
      end

      # @return [String]
      def separator
        divide_by_separator[1]
      end

      private

      # @return [(String, String, String), nil]
      def divide_by_separator
        @divide_by_separator ||= begin
          rev_content = content.to_s.reverse
          if match_data = rev_content.match(SEPARATOR_PATTERN)
            [match_data.post_match.reverse, match_data.to_s, match_data.pre_match.reverse]
          else
            ["Object", "::", content.to_s]
          end
        end
      end

      class << self
        # @param content [Address, #to_s]
        # @return [Address]
        def of(content)
          case content
          when Address
            content
          else
            new(content: normalize(content.to_s))
          end
        end

        # @param address_string [String]
        # @return [String]
        def normalize(address_string)
          parts = address_string.split(CONSTANT_SEPARATOR)

          if parts.empty?
            # Treat empty string as root (Object)
            return 'Object'
          end

          if parts.first.empty?
            # Treat leading double colon as root (Object)
            parts = ['Object'] + parts[1..]
          end

          if parts.last.start_with?(/[a-z]/)
            # If the last part start with a lower character, treat it as a method name
            if parts.length == 1
              parts = ["Object.#{parts[-1]}"]
            else
              parts = parts[..-3] + ["#{parts[-2]}.#{parts[-1]}"]
            end
          end

          # Remove redundunt `Object`.
          parts = parts.drop_while { |part| part == 'Object' }
          if parts.empty?
            return 'Object'
          end

          parts.join(CONSTANT_SEPARATOR)
        end
      end
    end
  end
end
