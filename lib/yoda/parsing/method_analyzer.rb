module Yoda
  module Parsing
    class MethodAnalyzer
      include AstTraversable

      # @param registry [Registry]
      # @param source   [String]
      # @param location [Location]
      # @return [SourceAnalyzer]
      def self.from_source(registry, source, location)
        source_analyzer = SourceAnalyzer.from_source(source, location)
        new(registry, source_analyzer.current_method_node, source_analyzer.current_namespace_nodes, location)
      end

      attr_reader :method_node, :current_location, :registry, :namespace_nodes
      # @param registry         [Registry]
      # @param method_node      [::Parser::AST::Node]
      # @param namespace_nodes  [Array<::Parser::AST::Node>]
      # @param current_location [Location]
      def initialize(registry, method_node, namespace_nodes, current_location)
        fail ArgumentError, method_node unless method_node.is_a?(::Parser::AST::Node)

        @registry = registry
        @method_node = method_node
        @namespace_nodes = namespace_nodes
        @current_location = current_location
      end

      def method_completion_worker
        @method_completion_worker ||= SendMethodCompletion.new(self)
      end

      # @return [Array<YARD::CodeObjects::Base>]
      def complete
        method_completion_worker.method_candidates
      end

      def current_node_worker
        @current_node_worker ||= CurrentNodeTypeExplain.new(self)
      end

      # @return [Store::Types::Base]
      def calculate_current_node_type
        current_node_worker.current_node_type
      end

      # @return [Range]
      def current_node_range
        current_node_worker.current_node_range
      end

      def namespace_path
        @namespace_path ||= @namespace_nodes.map { |node| [:class, :module].include?(node.type) ? node.children[0] : nil }.compact.reduce('', &method(:reduce_const_nodes))
      end

      def namespace_object
        @namespace ||= registry.find(namespace_path)
      end

      def method_path
        @method_path ||= namespace_path + (method_node.type == :def ? '#' : '.') + method_name.to_s
      end

      def method_object
        @method ||= registry.find(method_path)
      end

      def function
        @function ||= Store::Function.new(method_object)
      end

      def evaluation_context
        @context ||= Typing::Context.new(registry, namespace_object, namespace_object)
      end

      # @param  code_node [::Parser::AST::Node]
      # @return [Typing::Environment]
      def calculate_type(code_node)
        evaluator = Typing::Evaluator.new(evaluation_context)
        _type, tyenv = evaluator.process(method_body_node, create_evaluation_env)
        receiver_type, _tyenv = evaluator.process(code_node, tyenv)
        receiver_type
      end

      # @param node [::AST::Node]
      def reduce_const_nodes(name, node)
        paths = []
        while true
          return name + '::' +  paths.join('::') unless node
          return paths.join('::')  if node.type == :cbase
          paths.unshift(node.children[1])
          node = node.children[0]
        end
      end

      def nodes_to_current_location
        @nodes_to_current_location ||= calc_nodes_to_current_location(method_node, current_location)
      end

      def method_name
        @method_node.children[-3]
      end

      private

      def method_arg_node
        @method_node.children[-2]
      end

      def method_body_node
        @method_node.children[-1]
      end

      def create_evaluation_env
        env = Typing::Environment.new
        function.parameter_types.each do |name, type|
          name = name.gsub(/:\Z/, '')
          env.bind(name, type)
        end
        env
      end

      class SendMethodCompletion
        attr_reader :analyzer

        # @param analyzer [MethodAnalyzer]
        def initialize(analyzer)
          @analyzer = analyzer
        end

        def nearest_send_node
          @nearest_send_node ||= analyzer.nodes_to_current_location.reverse.find { |node| node.type == :send }
        end

        def on_selector?
          nearest_send_node && analyzer.current_location.included?(nearest_send_node.location.selector)
        end

        # @return [String, nil]
        def index_word
          return nil unless nearest_send_node
          @index_word ||= begin
            offset = analyzer.current_location.offset_from_begin(nearest_send_node.location.selector)[:column]
            nearest_send_node.children[1].to_s.slice(0..offset)
          end
        end

        # @return [Parser::AST::Node, nil]
        def nearest_receiver_node
          nearest_send_node && nearest_send_node.children[0]
        end

        # @return [Store::Types::Base, nil]
        def receiver_type
          @receiver_type ||= nearest_receiver_node && analyzer.calculate_type(nearest_receiver_node)
        end

        # @return [Array<YARD::CodeObjects::MethodObject>]
        def method_candidates
          return [] if !nearest_send_node || !on_selector?
          class_candidates = analyzer.evaluation_context.find_class_candidates(receiver_type)
          analyzer.evaluation_context.find_instance_method_candidates(class_candidates, /\A#{index_word}/)
        end
      end

      class CurrentNodeTypeExplain
        attr_reader :analyzer

        # @param analyzer [MethodAnalyzer]
        def initialize(analyzer)
          @analyzer = analyzer
        end

        # @return [Parser::AST::Node]
        def current_node
          analyzer.nodes_to_current_location.last
        end

        # @return [Range]
        def current_node_range
          Range.of_ast_location(current_node.location)
        end

        # @return [Store::Types::Base]
        def current_node_type
          @current_node_type ||= analyzer.calculate_type(current_node)
        end
      end
    end
  end
end
