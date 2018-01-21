require 'yard'

module Yoda
  module Store
    class Registry
      class << self
        # @return [Yoda::Store::Registory]
        def instance
          @instance ||= new
        end
      end

      # @param path [String, Symbol, Path]
      # @param code_object [YARD::CodeObject::Base]
      def register(code_object)
        YARD::Registry.register(code_object)
      end

      def clear
        YARD::Registry.clear
      end

      def save(path)
        YARD::Registry.save(false, path)
      end

      def load(path)
        YARD::Registry.load_yardoc(path)
      end

      # @param path [String, Symbol, Path]
      # @param code_object [Symbol, String]
      def at(path)
        if path.is_a?(Symbol)
          YARD::Registry.at(path)
        else
          YARD::Registry.at(path.gsub(/\A::/, ''))
        end
      end

      # @param path [String, Symbol, Path]
      def find(path)
        if path.is_a?(Path)
          YARD::Registry.resolve(path.namespace, path.name.gsub(/\A::/, ''))
        elsif path.is_a?(Symbol)
          at(path)
        else
          at(path.gsub(/\A::/, ''))
        end
      end

      # @param path [String, Symbol, Path]
      # @return [String, Symbol]
      def path_name_of(path)
        if path.is_a?(Path)
          path.name.gsub(/\A::/, '')
        elsif path.is_a?(Symbol)
          path
        else
          path.gsub(/\A::/, '')
        end
      end

      # @param code_object [String, Path]
      # @return [YARD::CodeObjects::Base, YARD::CodeObjects::Proxy]
      def find_or_proxy(path)
        find(path) || YARD::CodeObjects::Proxy.new(YARD::Registry.root, path_name_of(path))
      end

      # @param basename [String]
      # @param prefix [String]
      # @return [Array<YARD::CodeObject::Base>]
      def search_objects_with_prefix(basename, prefix)
        prefix_path = ConstPath.new(prefix)
        path = ConstPath.new(basename).concat(prefix_path.spacename)
        namespace = at(path.to_s)
        if namespace
          namespace.children.select { |child| child.name.to_s.start_with?(prefix_path.basename) }
        else
          []
        end
      end

      class ConstPath
        attr_reader :name

        # @param path [ConstPath, String]
        # @return [ConstPath]
        def self.of_path(path)
          path.is_a?(ConstPath) ? path : new(path)
        end

        # @param name [String]
        def initialize(name)
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

        # @param another [ConstPath, String]
        # @return [ConstPath]
        def concat(another)
          if self.class.of_path(another).absolute?
            self
          else
            self.class.new([self.to_s, another.to_s].reject(&:empty?).join('::'))
          end
        end
      end
    end
  end
end
