module Yoda
  module Typing
    module Types
      class VirtualMethod
        class Call
          # @return [Model::Parameters::Base]
          attr_reader :parameter

          # @param parameter [Model::Parameters::Multiple]
          def initialize(parameter)
            @parameter = parameter
          end

          
          # @return [Inferencer::TypeBinding]
          def binds
            @binds ||= begin
              binds = Inferencer::TypeBinding.new
              parameter.names.each do 
              end
            end
          end
        end

        # @param parameter [Model::Parameters::Multiple]
        def bind_arguments(parameter)
        end

        # @param parameter [Model::Parameters::Multiple]
        def bind_call(block_parameter)
        end
      end
    end
  end
end
