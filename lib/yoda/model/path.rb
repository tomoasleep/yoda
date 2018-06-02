module Yoda
  module Model
    class Path
      attr_reader :name

      # @param path [Path, String]
      # @return [Path]
      def self.build(path)
        path.is_a?(Path) ? path : new(path)
      end

      # @param names [Array<Path, String>]
      # @return [Path]
      def self.from_names(names)
        new(names.join('::'))
      end

      # @param name [String]
      def initialize(name)
        fail ArgumentError, name unless name.is_a?(String)
        @name = name
      end

      def absolute?
        name.start_with?('::')
      end

      # @return [String]
      def basename
        @basename ||= begin
          if name.end_with?('::')
            ''
          else
            name.split('::').last || ''
          end
        end
      end

      # @return [String]
      def spacename
        @spacename ||= begin
          if name.end_with?('::')
            name.gsub(/::\Z/, '')
          else
            name.split('::').slice(0..-2).join('::')
          end
        end
      end

      # @return [String]
      def to_s
        name
      end

      def split
        name.gsub(/\A::/, '').split('::') + (name.end_with?('::') ? [''] : [])
      end

      # @param another [Path, String]
      # @return [Path]
      def concat(another)
        if self.class.build(another).absolute?
          self
        else
          self.class.new([self.to_s, another.to_s].reject(&:empty?).join('::'))
        end
      end

      # @return [Array<String>]
      def namespaces
        name.split('::')
      end

      # @return [Array<Path>]
      def parent_paths
        if spacename.empty?
          []
        else
          [spacename] + Path.new(spacename).parent_paths
        end
      end

      def hash
        [self.class.name, name].hash
      end

      def ==(another)
        eql?(another)
      end

      def eql?(another)
        another.is_a?(Path) && name == another.name
      end
    end
  end
end
