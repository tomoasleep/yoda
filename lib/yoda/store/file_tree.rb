module Yoda
  module Store
    class FileTree
      # @return [String, nil]
      attr_reader :base_path

      # @param base_path [String, nil]
      def initialize(base_path:)
        @base_path = base_path ? File.absolute_path(base_path) : nil
      end

      def open_at(path)
        normalized_path = normalize_path(path)
        content = read_at(normalized_path)
        notify_changed(path: normalized_path, content: content)
        content
      end

      # @param path [String]
      # @return [String, nil]
      def read_at(path)
        editing_content[normalize_path(path)] || read_real_at(path)
      end

      # @param path [String]
      # @return [String, nil]
      def read_real_at(path)
        if File.file?(path)
          File.read(path)
        else
          nil
        end
      end

      # @param path [String]
      # @param content [String]
      def set_editing_at(path, content)
        normalized_path = normalize_path(path)
        editing_content[normalized_path] = content
        notify_changed(path: normalized_path, content: content)
      end

      # @param path [String]
      # @return [Boolean]
      def editing_at?(path)
        editing_content.has_key?(normalize_path(path))
      end

      # @param path [String]
      # @return [void]
      def clear_editing_at(path)
        normalized_path = normalize_path(path)
        editing_content.delete(normalized_path)
        notify_changed(path: normalized_path, content: read_real_at(normalized_path))
      end

      # @param path [String]
      # @return [void]
      def mark_deleted(path)
        normalized_path = normalize_path(path)
        editing_content.delete(normalized_path)
        notify_changed(path: normalized_path, content: nil)
      end

      # @param path [String]
      # @return [String]
      def normalize_path(path)
        if base_path
          File.expand_path(path, base_path)
        else
          File.absolute_path(path)
        end
      end

      # @param path [String]
      # @return [Boolean]
      def subpath?(path)
        if base_path
          File.fnmatch("#{base_path}/**/*", path)
        else
          false
        end
      end

      # @yield [path:, content:]
      # @yieldparam path [String]
      # @yieldparam content [String, nil]
      def on_change(&handler)
        changed_events.listen(&handler)
      end

      private

      # @param path [String]
      # @param content [String, nil]
      def notify_changed(path:, content:)
        changed_events.notify(path: path, content: content)
      end

      # @return [Hash{String => String}]
      def editing_content
        @editing_content ||= Concurrent::Map.new
      end

      # @return [EventSet]
      def changed_events
        @changed_events ||= EventSet.new
      end

      class EventSet
        # @return [Array<#call>]
        attr_reader :listeners

        def initialize
          @listeners = []
        end

        # @param listener [#call]
        def listen(&listener)
          listeners << listener
        end

        def notify(**kwargs)
          listeners.each do |listener|
            listener.call(**kwargs)
          end
        end
      end
    end
  end
end
