module Yoda
  module Parsing
    class MethodAnalyzer
      include AstTraversable

      # @param registry [Registry]
      # @param source   [String]
      # @param location [Location]
      # @return [MethodAnalyzer]
      def self.from_source(registry, source, location)
        source_analyzer = SourceAnalyzer.from_source(source, location)
        from_source_analyzer(registry, source_analyzer)
      end

      # @param registry [Registry]
      # @param source_analyzer [SourceAnalyzer]
      # @return [MethodAnalyzer]
      def self.from_source_analyzer(registry, source_analyzer)
        fail RuntimeError, "There are no method at #{source_analyzer.location}" unless source_analyzer.current_method_node
        new(registry, source_analyzer.current_method_node, source_analyzer.current_namespace_nodes, source_analyzer.location)
      end

      attr_reader :method_node, :current_location, :registry, :namespace_nodes
      attr_reader :method_completion_worker, :current_method_reference_calculator, :current_node_worker, :nearest_method_worker
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

        @method_completion_worker = SendMethodCompletion.new(self)
        @nearest_method_worker = NearestMethodDiscovery.new(self)
        @current_method_reference_calculator = CurrentMethodReferenceCalculator.new(self)
        @current_node_worker = CurrentNodeTypeExplain.new(self)
      end

      # @return [Array<YARD::CodeObjects::Base>]
      def complete
        method_completion_worker.method_candidates
      end

      # @return [Range, nil]
      def complete_substitution_range
        method_completion_worker.substitution_range
      end

      # @return [Array<YARD::CodeObjects::Base>]
      def calculate_references
        current_method_reference_calculator.method_candidates
      end

      # @return [Array<YARD::CodeObjects::Base>]
      def current_methods
        current_method_reference_calculator.method_candidates
      end

      # @return [Array<YARD::CodeObjects::Base>]
      def nearest_methods
        nearest_method_worker.method_candidates
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
        (@method ||= registry.find(method_path)) || fail(RuntimeError, "Not method path #{method_path}")
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

      module NearestSendNodeAnalyzable
        def nearest_send_node
          @nearest_send_node ||= analyzer.nodes_to_current_location.reverse.find { |node| node.type == :send }
        end

        def on_selector?
          nearest_send_node && analyzer.current_location.included?(nearest_send_node.location.selector)
        end

        def on_dot?
          nearest_send_node && nearest_send_node.location.dot && analyzer.current_location.included?(nearest_send_node.location.dot)
        end

        # @return [Parser::AST::Node, nil]
        def nearest_receiver_node
          nearest_send_node && nearest_send_node.children[0]
        end

        # @return [Range]
        def selector_range
          Range.of_ast_location(nearest_send_node.location.selector)
        end

        # @return [Range, nil]
        def dot_range
          nearest_send_node.location.dot && Range.of_ast_location(nearest_send_node.location.dot)
        end

        # @return [Location, nil]
        def next_location_to_dot
          nearest_send_node.location.dot && Range.of_ast_location(nearest_send_node.location.dot).end_location
        end

        def name_to_send
          nearest_send_node.children[1].to_s
        end
      end

      class SendMethodCompletion
        include NearestSendNodeAnalyzable
        attr_reader :analyzer

        # @param analyzer [MethodAnalyzer]
        def initialize(analyzer)
          @analyzer = analyzer
        end

        # @return [String, nil]
        def index_word
          return nil unless nearest_send_node
          @index_word ||= begin
            if on_selector?
              offset = analyzer.current_location.offset_from_begin(nearest_send_node.location.selector)[:column]
              name_to_send.slice(0..offset)
            else
              ''
            end
          end
        end

        # @return [Range, nil]
        def substitution_range
          return selector_range if on_selector?
          return Range.new(next_location_to_dot, next_location_to_dot) if on_dot?
          nil
        end

        # @return [Store::Types::Base, nil]
        def receiver_type
          @receiver_type ||= begin
            if nearest_receiver_node
              analyzer.calculate_type(nearest_receiver_node)
            else
              Store::Types::InstanceType.new(analyzer.namespace_object.path)
            end
          end
        end

        # @return [Array<YARD::CodeObjects::MethodObject>]
        def method_candidates
          return [] if !nearest_send_node || (!on_selector? && !on_dot?)
          class_candidates = analyzer.evaluation_context.find_class_candidates(receiver_type)
          analyzer.evaluation_context.find_instance_method_candidates(class_candidates, /\A#{index_word}/)
        end
      end

      class SendNodeAnalyzer
        attr_reader :send_node

        # @param send_node [::Parser::AST::Node]
        def initialize(send_node)
          @send_node = send_node
        end

        def on_selector?(location)
          send_node.location.dot && selector_range.include?(location)
        end

        # @param location [Location]
        # @return [true, false]
        def on_dot?(location)
          send_node.location.dot && dot_range.include?(location)
        end

        # @param location [Location]
        # @return [true, false]
        def on_parameter?(location)
          parameter_range.include?(location)
        end

        # @return [Range]
        def parameter_range
          @parameter_range ||=
            Range.new(
              Location.of_ast_location(send_node.location.selector.end),
              Location.of_ast_location(send_node.location.expression.end).move(row: 0, column: -1),
            )
        end

        # @return [Range]
        def selector_range
          @selector_range ||= Range.of_ast_location(send_node.location.selector)
        end

        # @return [Range, nil]
        def dot_range
          @dot_range ||= send_node.location.dot && Range.of_ast_location(send_node.location.dot)
        end

        # @return [Location, nil]
        def next_location_to_dot
          send_node.location.dot && Range.of_ast_location(send_node.location.dot).end_location
        end

        # @return [Parser::AST::Node, nil]
        def receiver_node
          send_node && send_node.children[0]
        end

        # @return [String]
        def sending_name
          send_node.children[1].to_s
        end
      end

      class NearestMethodDiscovery
        attr_reader :analyzer

        # @param analyzer [MethodAnalyzer]
        def initialize(analyzer)
          @analyzer = analyzer
        end

        # @return [::Parser::AST::Node, nil]
        def nearest_send_node
          @nearest_send_node ||= analyzer.nodes_to_current_location.reverse.find do |node|
            node.type == :send && SendNodeAnalyzer.new(node).on_parameter?(analyzer.current_location)
          end
        end

        # @return [SendNodeAnalyzer, nil]
        def send_node_analyzer
          @send_node_analyzer ||= nearest_send_node && SendNodeAnalyzer.new(nearest_send_node)
        end

        # @return [String, nil]
        def index_word
          send_node_analyzer&.sending_name
        end

        # @return [Range, nil]
        def substitution_range
          return selector_range if on_selector?
          return Range.new(next_location_to_dot, next_location_to_dot) if on_dot?
          nil
        end

        # @return [Store::Types::Base]
        def receiver_type
          @receiver_type ||= begin
            if nearest_send_node
              analyzer.calculate_type(send_node_analyzer.receiver_node)
            else
              Store::Types::InstanceType.new(analyzer.namespace_object.path)
            end
          end
        end

        # @return [Array<YARD::CodeObjects::MethodObject>]
        def method_candidates
          return [] unless nearest_send_node
          class_candidates = analyzer.evaluation_context.find_class_candidates(receiver_type)
          analyzer.evaluation_context.find_instance_method_candidates(class_candidates, index_word)
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

      class CurrentMethodReferenceCalculator
        attr_reader :analyzer

        # @param analyzer [MethodAnalyzer]
        def initialize(analyzer)
          @analyzer = analyzer
        end

        # @return [Parser::AST::Node]
        def current_node
          analyzer.nodes_to_current_location.last
        end

        # @return [Store::Types::Base]
        def current_node_type
          @current_node_type ||= analyzer.calculate_type(current_node)
        end

        # @return [true, false]
        def on_send_node?
          current_node.type == :send
        end

        # @return [String, nil]
        def index_word
          return nil unless on_send_node?
          @index_word ||= current_node.children[1].to_s
        end

        # @return [Parser::AST::Node, nil]
        def current_receiver_node
           on_send_node? ? nearest_send_node.children[0] : nil
        end

        # @return [Store::Types::Base, nil]
        def receiver_type
          @receiver_type ||= current_receiver_node && analyzer.calculate_type(current_receiver_node)
        end

        # @return [Array<YARD::CodeObjects::MethodObject>]
        def method_candidates
          return [] unless on_send_node?
          class_candidates = analyzer.evaluation_context.find_class_candidates(receiver_type)
          analyzer.evaluation_context.find_instance_method_candidates(class_candidates, index_word)
        end
      end

      class CurrentMethodReferenceCalculator
        attr_reader :analyzer

        # @param analyzer [MethodAnalyzer]
        def initialize(analyzer)
          @analyzer = analyzer
        end

        # @return [Parser::AST::Node]
        def current_node
          analyzer.nodes_to_current_location.last
        end

        # @return [Store::Types::Base]
        def current_node_type
          @current_node_type ||= analyzer.calculate_type(current_node)
        end

        # @return [true, false]
        def on_send_node?
          current_node.type == :send
        end

        # @return [String, nil]
        def index_word
          return nil unless on_send_node?
          @index_word ||= current_node.children[1].to_s
        end

        # @return [Parser::AST::Node, nil]
        def current_receiver_node
           on_send_node? ? nearest_send_node.children[0] : nil
        end

        # @return [Store::Types::Base, nil]
        def receiver_type
          @receiver_type ||= current_receiver_node && analyzer.calculate_type(current_receiver_node)
        end

        # @return [Array<YARD::CodeObjects::MethodObject>]
        def method_candidates
          return [] unless on_send_node?
          class_candidates = analyzer.evaluation_context.find_class_candidates(receiver_type)
          analyzer.evaluation_context.find_instance_method_candidates(class_candidates, index_word)
        end
      end

      class CurrentConstantReferenceCalculator
      end
    end
  end
end
