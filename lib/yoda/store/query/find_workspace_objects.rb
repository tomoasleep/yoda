module Yoda
  module Store
    module Query
      class FindWorkspaceObjects < Base
        # @param query [String]
        # @return [Enumerator<Objects::Base>]
        def select(query)
          lazy_select(query)
        end

        private

        # @param query [String]
        # @return [Enumerator::Lazy<Objects::Base>]
        def lazy_select(query)
          registry.local_store.items.lazy.select do |item|
            item.primary_source && fuzzy_match?(item.name, query)
          end
        end

        # @param name [String]
        # @param query [String, Regexp]
        # @return [true, false]
        def fuzzy_match?(name, query)
          left_chars = query.chars
          name.each_char do |c|
            break if left_chars.empty?
            left_chars.shift if c == left_chars.first
          end

          left_chars.empty?
        end
      end
    end
  end
end
