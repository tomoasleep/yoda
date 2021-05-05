module Yoda
  module Model
    module TypeExpressions
      # @abstract
      class Base
        def ==(another)
          eql?(another)
        end

        # @abstract
        # @param new_lexical_context [LexicalContext]
        # @return [Base]
        def change_root(new_lexical_context)
          fail NotImplementedError
        end

        # @abstract
        # @param registry [Registry]
        # @return [Array<Store::Objects::Base>]
        def resolve(registry)
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def to_s
          fail NotImplementedError
        end

        # @abstract
        # @param env [Environment]
        # @return [RBS::Types::Bases::Base, RBS::Types::Variable, RBS::Types::ClassSingleton, RBS::Types::Interface, RBS::Types::ClassInstance, RBS::Types::Alias, RBS::Types::Tuple, RBS::Types::Record, RBS::Types::Optional, RBS::Types::Union, RBS::Types::Intersection, RBS::Types::Function, RBS::Types::Block, RBS::Types::Proc, RBS::Types::Literal]
        def to_rbs_type(env)
          fail NotImplementedError
        end

        # @return [Base]
        def map
          yield self
        end
      end
    end
  end
end
