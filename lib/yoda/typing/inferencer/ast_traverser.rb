require 'forwardable'

module Yoda
  module Typing
    class Inferencer
      class AstTraverser
        extend Forwardable

        # @return [Tracer]
        attr_reader :tracer

        # @return [BaseContext]
        attr_reader :context

        delegate [:bind_context, :bind_type, :bind_send] => :tracer

        # @param tracer [Tracer]
        # @param context [BaseContext]
        def initialize(tracer:, context:)
          @tracer = tracer
          @context = context
        end

        # @param node [AST::Vnode]
        # @return [Store::Types::Base]
        def traverse(node)
          bind_context(node: node, context: context)
          Logger.trace("Traversing #{node}")
          type = infer_node(node)
          Logger.trace("Traversed #{node} -> #{type.to_type_string}")
          bind_type(node: node, type: type, context: context)

          type
        end

        private

        # @return [Types::Generator]
        def generator
          @generator ||= Types::Generator.new(context.registry)
        end

        # @param context [Context]
        # @return [self]
        def derive(context:)
          self.class.new(tracer: tracer, context: context)
        end

        # @param node [AST::Vnode]
        # @return [Store::Types::Base]
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
            Types::Union.new(node.children.map { |node| traverse(node) })
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
            type_for_literal_sexp(node.type)
          when :return, :break, :next
            # TODO
            node.arguments[0] ? traverse(node.arguments[0]) : generator.nil_type
          when :resbody
            # TODO
            traverse(node.children[2])
          when :csend, :send
            infer_send_node(node)
          when :block
            infer_block_call_node(node)
          when :cbase
            infer_const_base_node(node)
          when :const
            infer_const_node(node)
          when :lvar, :cvar, :ivar, :gvar
            context.environment.resolve(node.name) || generator.any_type
          when :begin, :kwbegin, :block
            node.children.map { |node| traverse(node) }.last
          when :dstr, :dsym, :xstr
            node.children.each { |node| traverse(node) }
            type_for_literal_sexp(node.type)
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
          when :module, :class
            infer_namespace_node(node)
          else
            type_for_literal_sexp(node.type)
          end
        end

        # @param node [AST::ArgumentNode]
        # @return [Store::Types::Base]
        def infer_assignment_node(node)
          body_type = traverse(node.content)
          context.environment.bind(node.assignee.name, body_type)
          body_type
        end

        # @param node [AST::ConstantBaseNode]h
        # @return [Types::Base]
        def infer_const_base_node(node)
          object = Store::Query::FindConstant.new(context.registry).find('::')

          case object
          when Store::Objects::NamespaceObject
            generator.singleton_type_of(object.path)
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
          object = 
            if node.base.present?
              base_type = traverse(node.base)
              base_objects = ObjectResolver.new(registry: context.registry, generator: generator).call(base_type)
              # TODO: Support multiple candidate
              Store::Query::FindConstant.new(context.registry).find(Model::Path.from_names([base_objects.first.path, node.name.name]))
            else
              Store::Query::FindConstant.new(context.registry).find(Model::ScopedPath.new(context.lexical_scope_objects.map(&:path), node.name.name.to_s))
            end

          case object
          when Store::Objects::NamespaceObject
            generator.singleton_type_of(object.path)
          when Store::Objects::ValueObject
            # TODO
            generator.any_type
          else
            generator.any_type
          end
        end

        # @param node [AST::DefNode]
        # @return [Types::Base]
        def infer_method_node(node)
          receiver_type = generator.union(context.current_objects.map { |object| generator.instance_type(object) })

          method_definition_provider = MethodDefinitionResolver.new(
            receiver_type: receiver_type,
            name: node.name,
            registry: context.registry,
            generator: generator,
          )

          method_context = method_definition_provider.generate_method_context(context: context, params_node: node.parameters)
          derive(context: method_context).traverse(node.body)

          generator.symbol_type
        end

        # @param node [AST::DefSingletonNode]
        # @return [Types::Base]
        def infer_smethod_node(node)
          receiver_type = traverse(node.receiver)

          method_definition_provider = MethodDefinitionResolver.new(
            receiver_type: receiver_type,
            name: node.name,
            registry: context.registry,
            generator: generator,
          )

          method_context = method_definition_provider.generate_method_context(context: context, params_node: node.parameters)
          derive(context: method_context).traverse(node.body)

          generator.symbol_type
        end

        # @param node [AST::ModuleNode, AST::ClassNode]
        # @return [Types::Base]
        def infer_namespace_node(node)
          namespace_type = traverse(node.receiver)
          namespace_objects = ObjectResolver.new(registry: context.registry, generator: generator).call(namespace_type)

          block_context = NamespaceContext.new(objects: namespace_objects, parent: context, registry: context.registry, receiver: namespace_type)
          derive(context: block_context).traverse(node.body)

          namespace_type
        end

        # @param node [AST::HashNode]
        # @return [Model::TypeExpressions::Base]
        def infer_hash_node(node)
          hash = node.contents.each_with_object({}) do |node, memo|
            case node.type
            when :pair
              case node.key.type
              when :sym, :str
                memo[node.key.value.to_s] = traverse(node.value)
              else
                # TODO: Support other key types.
              end
            when :kwsplat
              traverse(node.content)
              # TODO: merge infered result
            end
          end

          Types::AssociativeArray.new(contents: hash)
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

          # argument_types = node.arguments.map { |node| traverse(node) }
          # arguments = Arguments.new(node.arguments, tracer)

          method_resolver = MethodResolver.new(
            registry: context.registry,
            receiver_type: receiver_type,
            name: node.selector_name,
            argument_types: argument_types,
            generator: generator,
            implicit_receiver: node.implicit_receiver?,
          )

          if block_node
            new_context = method_resolver.generate_block_context(context: context, block_param_node: block_param_node)
            derive(context: new_context).traverse(block_node)
          end

          bind_send(node: node, method_candidates: method_resolver.method_candidates, receiver_candidates: method_resolver.receiver_candidates)
          method_resolver.return_type
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
          Types::Union.new(branch_nodes.map { |node| traverse(node) })
        end

        # @param node [::AST::Node]
        # @return [[Store::Types::Base, Environment]]
        def infer_case_node(node)
          # TODO
          subject_node, *when_nodes, else_node = node.children
          when_body_nodes = when_nodes.map { |node| node.children.last }
          Types::Union.new([*when_body_nodes, else_node].compact.map { |node| traverse(node) })
        end

        # @param sexp_type [::Symbol, nil]
        # @return [Types::Base]
        def type_for_literal_sexp(sexp_type)
          case sexp_type
          when :dstr, :str, :xstr, :string
            generator.string_type
          when :dsym, :sym
            generator.symbol_type
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
            generator.integer_type
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
