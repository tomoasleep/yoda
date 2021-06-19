require 'forwardable'

module Yoda
  module Typing
    class Inferencer
      class AstTraverser
        extend Forwardable

        # @return [Tracer]
        attr_reader :tracer

        # @return [Contexts::BaseContext]
        attr_reader :context

        delegate [:bind_context, :bind_type, :bind_send] => :tracer

        # @return [Types::Generator]
        delegate [:generator] => :context

        # @param tracer [Tracer]
        # @param context [ContextsBaseContext]
        def initialize(tracer:, context:)
          @tracer = tracer
          @context = context
        end

        # @param node [AST::Vnode]
        # @return [RBS::Types::t]
        def traverse(node)
          bind_context(node: node, context: context)
          Logger.trace("Traversing #{node}")
          type = infer_node(node)
          Logger.trace("Traversed #{node} -> #{type.to_s}")
          bind_type(node: node, type: type, context: context)

          type
        end

        private

        # @param context [Contexts::BaseContext]
        # @return [self]
        def derive(context:)
          self.class.new(tracer: tracer, context: context)
        end

        # @param node [AST::Vnode]
        # @return [Types::Type]
        def infer_node(node)
          case node.type
          when :lvasgn, :ivasgn, :cvasgn, :gvasgn
            infer_assignment_node(node)
          when :casgn
            # TODO
            traverse(node.content)
          when :masgn
            # TODO
            traverse(node.content)
          when :op_asgn, :or_asgn, :and_asgn
            # TODO
            traverse(node.content)
          when :and, :or, :not
            # TODO
            generator.union_type(*node.children.map { |node| traverse(node) })
          when :if
            infer_branch_nodes(node.children.first, node.children.slice(1..2).compact)
          when :while, :until, :while_post, :until_post
            # TODO
            traverse(node.body)
          when :for
            # TODO
            traverse(node.body)
          when :case
            infer_case_node(node)
          when :super, :zsuper, :yield
            # TODO
            type_for_literal_sexp(node)
          when :return, :break, :next
            # TODO
            node.arguments[0] ? traverse(node.arguments[0]) : generator.nil_type
          when :ensure
            infer_ensure_node(node)
          when :rescue
            infer_rescue_node(node)
          when :resbody
            infer_resbody_node(node)
          when :csend, :send
            infer_send_node(node)
          when :block
            infer_block_call_node(node)
          when :const
            infer_const_node(node)
          when :lvar, :cvar, :ivar, :gvar
            context.type_binding.resolve(node.name) || generator.any_type
          when :begin, :kwbegin, :block
            node.children.map { |node| traverse(node) }.last
          when :dstr, :dsym, :xstr
            node.children.each { |node| traverse(node) }
            type_for_literal_sexp(node)
          when :def
            infer_method_node(node)
          when :defs
            infer_smethod_node(node)
          when :hash
            infer_hash_node(node)
          when :self
            context.receiver
          when :defined
            generator.boolean_type
          when :class
            infer_class_node(node)
          when :module
            infer_namespace_node(node)
          when :sclass
            infer_singleton_class_node(node)
          else
            type_for_literal_sexp(node)
          end
        end

        # @param node [AST::ArgumentNode]
        # @return [Store::Types::Base]
        def infer_assignment_node(node)
          body_type = traverse(node.content)
          context.type_binding.bind(node.assignee.name, body_type)
          body_type
        end

        # @param node [AST::ConstantBaseNode]h
        # @return [Types::Base]
        def infer_const_base_node(node)
          object = Store::Query::FindConstant.new(context.registry).find('::')

          case object
          when Store::Objects::NamespaceObject
            generator.singleton_type_at(object.path)
          when Store::Objects::ValueObject
            # TODO
            generator.any_type
          else
            generator.any_type
          end
        end

        # @param node [AST::ConstantNode]
        # @return [Types::Base]
        def infer_const_node(node)
          case node.base.type
          when :cbase
            # Remember constant candidates
            constants = [context.environment.resolve_constant(node.name.name.to_s)].compact
            tracer.bind_constants(node: node, constants: constants)

            generator.singleton_type_at("::#{node.name.name}")
          when :empty
            lexical_values = context.lexical_scope_types.map(&:value)
            relative_path = node.name.name.to_s

            # Search nearest lexical scope first
            found_paths = lexical_values.reverse.reduce(nil) do |found_paths, value|
              found_paths || begin
                current_found_paths = value.select_constant_paths(relative_path)
                current_found_paths.empty? ? nil : current_found_paths
              end
            end

            if found_paths
              # Remember constant candidates
              constants = [context.environment.resolve_constant(found_paths.first)].compact
              tracer.bind_constants(node: node, constants: constants)
            
              generator.singleton_type_at(found_paths.first)
            else
              generator.any_type
            end
          else
            base_type = traverse(node.base)

            # Remember constant candidates
            paths = base_type.value.select_constant_paths(node.name.name.to_s)
            constants = paths.map { |path| context.environment.resolve_constant(path) }.compact
            tracer.bind_constants(node: node, constants: constants)

            generator.wrap_rbs_type(base_type.value.select_constant_type(node.name.name.to_s))
          end
        end

        # @param node [AST::DefNode]
        # @return [Types::Base]
        def infer_method_node(node)
          traverse_method(node, receiver_type: context.method_receiver)
        end

        # @param node [AST::DefSingletonNode]
        # @return [Types::Base]
        def infer_smethod_node(node)
          traverse_method(node, receiver_type: traverse(node.receiver))
        end

        # @param node [AST::DefNode, AST::DefSingletonNode]
        # @param receiver_type [Types::Type]
        # @return [Types::Base]
        def traverse_method(node, receiver_type:)
          method_candidates = receiver_type.value.select_method(node.name.to_s, visibility: %i(private protected public))
          method_types = method_candidates.map(&:rbs_type)

          # TODO: Support overloads
          method_bind = method_types.reduce({}) do |all_bind, method_type|
            bind = ParameterBinder.new(node.parameters.parameter).bind(type: method_type, generator: generator)
            all_bind.merge(bind.to_h) { |_key, v1, v2| generator.union_type(v1, v2) }
          end

          Logger.trace("method_candidates: [#{method_candidates.join(', ')}]")
          Logger.trace("bind arguments: #{method_bind.map { |key, value| [key, value.to_s] }.to_h }")

          tracer.bind_method_definition(node: node, method_candidates: method_candidates)

          method_context = context.derive_method_context(receiver_type: receiver_type, binds: method_bind)
          derive(context: method_context).traverse(node.body)

          generator.symbol_type(node.name.to_sym)
        end

        # @param node [AST::SingletonClassNode]
        # @return [Types::Base]
        def infer_singleton_class_node(node)
          receiver_type = traverse(node.receiver)

          new_context = context.derive_class_context(class_type: receiver_type.singleton_type)
          derive(context: new_context).traverse(node.body)

          generator.nil_type
        end

        # @param node [AST::ClassNode]
        # @return [Types::Base]
        def infer_class_node(node)
          if super_class_node = node.super_class
            traverse(super_class_node)
          end

          infer_namespace_node(node)
        end

        # @param node [AST::ModuleNode, AST::ClassNode]
        # @return [Types::Base]
        def infer_namespace_node(node)
          namespace_type = traverse(node.receiver)

          new_context = context.derive_class_context(class_type: namespace_type)
          derive(context: new_context).traverse(node.body)

          namespace_type
        end

        # @param node [AST::HashNode]
        # @return [Model::TypeExpressions::Base]
        def infer_hash_node(node)
          hash = node.contents.each_with_object({}) do |node, memo|
            case node.type
            when :pair
              case node.key.type
              when :sym
                memo[node.key.value.to_sym] = traverse(node.value)
              when :str
                memo[node.key.value.to_s] = traverse(node.value)
              else
                # TODO: Support other key types.
              end
            when :kwsplat
              traverse(node.content)
              # TODO: merge infered result
            end
          end

          generator.record_type(hash)
        end

        # @param node [AST::BlockCallNode]
        def infer_block_call_node(node)
          infer_send_node(node.send_clause, node.parameters, node.body)
        end

        # @param node [AST::SendNode]
        # @param block_param_node [AST::ParametersNode, nil]
        # @param block_node [AST::Vnode, nil]
        # @return [Types::Base]
        def infer_send_node(node, block_param_node = nil, block_node = nil)
          receiver_type = node.implicit_receiver? ? context.receiver : traverse(node.receiver)
          argument_types = infer_argument_nodes(node.arguments)

          visibility = node.implicit_receiver? ? %i(private protected public) : %i(public)
          # TODO: Support overloads
          method_candidates = receiver_type.value.select_method(node.selector_name, visibility: visibility)
          method_types = method_candidates.map(&:rbs_type)

          if block_node
            # TODO: Resolve type variables by matching argument_types with arguments
            binds = ArgumentsBinder.new(generator: generator).bind(types: method_types, arguments: block_param_node.parameter)
            new_context = context.derive_block_context(binds: binds)
            derive(context: new_context).traverse(block_node)
          end

          Logger.trace("method_candidates: [#{method_candidates.join(', ')}]")
          Logger.trace("receiver_type: #{receiver_type}")

          bind_send(node: node, method_candidates: method_candidates, receiver_type: receiver_type)
          if method_types.empty?
            generator.unknown_type(reason: "method not found")
          else
            generator.union_type(*method_types.map { |method_type| method_type.type.return_type })
          end
        end

        # @param nodes [Array<::AST::Node>]
        # @return [{Symbol => Types::Base}]
        def infer_argument_nodes(argument_nodes)
          argument_nodes.each_with_object({}) do |node, obj|
            case node.type
            when :splat
              # TODO
              traverse(node)
            when :block_pass
              obj[:block_argument] = traverse(node.children.first)
            else
              obj[:arguments] ||= []
              obj[:arguments].push(traverse(node))
            end
          end
        end

        # @param condition_node [::AST::Node]
        # @param branch_nodes [Array<::AST::Node>]
        # @return [Types::Base]
        def infer_branch_nodes(condition_node, branch_nodes)
          traverse(condition_node)
          generator.union_type(*branch_nodes.map { |node| traverse(node) })
        end

        # @param node [::AST::Node]
        # @return [[Store::Types::Base, Environment]]
        def infer_case_node(node)
          # TODO
          subject_node, *when_nodes, else_node = node.children
          when_body_nodes = when_nodes.map { |node| node.children.last }
          generator.union_type(*[*when_body_nodes, else_node].compact.map { |node| traverse(node) })
        end

        # @param node [AST::EnsureNode]
        # @return [Types::Base]
        def infer_ensure_node(node)
          type = traverse(node.body)
          traverse(node.ensure_body)
          type
        end

        # @param node [AST::RescueNode]
        # @return [Types::Base]
        def infer_rescue_node(node)
          type = traverse(node.body)
          node.rescue_clauses.each { |rescue_clause| traverse(rescue_clause) }
          traverse(node.else_clause)
          type
        end

        # @param node [AST::RescueClauseNode]
        # @return [Types::Base]
        def infer_resbody_node(node)
          binds = {}

          exception_type = begin
            if node.match_clause
              case node.match_clause.type
              when :array
                generator.union_type(*node.match_clause.contents.map { |content| traverse(content).instance_type })
              when :empty
                generator.standard_error_type
              else
                # Unexpected
                generator.standard_error_type
              end
            else
              generator.standard_error_type
            end
          end


          if node.assignee
            case node.assignee.type
            when :lvasgn
              binds[node.assignee.assignee.name] = exception_type
            end
          end

          new_context = context.derive_block_context(binds: binds)
          derive(context: new_context).traverse(node.body)
        end

        # @param [AST::LiteralNode]
        # @return [Types::Base]
        def type_for_literal_sexp(node)
          case node.type
          when :dstr, :xstr
            generator.string_type
          when :str, :string
            generator.string_type(node.value.to_s)
          when :dsym
            generator.symbol_type
          when :sym
            generator.symbol_type(node.value.to_sym)
          when :array, :splat
            generator.array_type
          when :hash
            generator.hash_type
          when :irange, :erange
            generator.range_type
          when :regexp
            generator.regexp_type
          when :true
            generator.true_type
          when :false
            generator.false_type
          when :nil
            generator.nil_type
          when :int
            generator.integer_type(node.value.to_i)
          when :float
            generator.float_type
          when :complex
            generator.numeric_type
          when :rational
            generator.numeric_type
          when :empty
            generator.nil_type
          else
            generator.any_type
          end
        end
      end
    end
  end
end
