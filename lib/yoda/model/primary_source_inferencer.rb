module Yoda
  module Model
    class PrimarySourceInferencer
      def initialize
      end

      # @param object [Yoda::Store::Objects::Base]
      def infer_for_object(object)
        object.primary_source || infer_primary_source_from_object_sources(object)
      end

      private

      # @param object [Yoda::Store::Objects::Base]
      def infer_primary_source_from_object_sources(object)
        source_with_object_name =
          object.sources.find do |(source_file, _row, _column)|
            basename = File.basename(source_file, ".*")
            object.name == to_constant_name(basename)
          end

        return source_with_object_name if source_with_object_name

        object.sources.first
      end

      def to_constant_name(str)
        str = str.to_s.split("/").last
        # camelize
        str.sub(/^[a-z]*/) { |match| match.capitalize }.gsub(/(?:_)([a-z]*)/i) { $1.capitalize }
      end
    end
  end
end
