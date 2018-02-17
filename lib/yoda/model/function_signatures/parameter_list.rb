module Yoda
  module Model
    module FunctionSignatures
      class ParameterList
        # @return [Array<(String, String)>]
        attr_reader :parameters

        # @param parameters [Array<(String, String)>]
        def initialize(parameters)
          fail ArgumentError, parameters unless parameters.all? { |param| param.is_a?(Array) }
          @parameters = parameters
        end

        # @return [Array<(String, String)>]
        def to_a
          parameters
        end

        # @return [Enumerator<(String, String)>]
        def each(*args, &proc)
          to_a.each(*args, &proc)
        end

        # @return [Array<String>]
        def parameter_names
          parameters.map(&:first)
        end

        # @return [Array<String>]
        def required_parameters
          parameter_options[:required_parameters]
        end

        # @return [Array<String>]
        def post_parameters
          parameter_options[:post_parameters]
        end

        # @return [Array<(String, String)>]
        def optional_parameters
          parameter_options[:optional_parameters]
        end

        # @return [Array<String>]
        def required_keyword_parameters
          parameter_options[:required_keyword_parameters]
        end

        # @return [Array<(String, String)>]
        def optional_keyword_parameters
          parameter_options[:optional_keyword_parameters]
        end

        # @return [String, nil]
        def rest_parameter
          parameter_options[:rest_parameter]
        end

        # @return [String, nil]
        def keyword_rest_parameter
          parameter_options[:keyword_rest_parameter]
        end

        # @return [String, nil]
        def block_parameter
          parameter_options[:block_parameter]
        end

        # @return [Hash{ Symbol => Object }]
        def parameter_options
          @parameter_options ||= begin
            options = {
              required_parameters: [],
              optional_parameters: [],
              rest_parameter: nil,
              post_parameters: [],
              required_keyword_parameters: [],
              optional_keyword_parameters: [],
              keyword_rest_parameter: nil,
              block_parameter: nil,
            }
            parameters.each_with_object(options) do |(name, default), obj|
              if name.to_s.start_with?('**')
                obj[:keyword_rest_parameter] ||= name.to_s.gsub(/\A\*\*/, '')
              elsif name.to_s.start_with?('*')
                obj[:rest_parameter] ||= name.to_s.gsub(/\A\*/, '')
              elsif name.to_s.start_with?('&')
                obj[:block_parameter] ||= name.to_s.gsub(/\A\&/, '')
              elsif name.to_s.end_with?(':')
                if default && !default.empty?
                  obj[:optional_keyword_parameters].push([name.to_s.gsub(/:\Z/, ''), default])
                else
                  obj[:required_keyword_parameters].push(name.to_s.gsub(/:\Z/, ''))
                end
              elsif default && !default.empty?
                obj[:optional_parameters].push([name, default])
              elsif obj[:rest_parameter]
                obj[:post_parameters].push(name.to_s)
              else
                obj[:required_parameters].push(name.to_s)
              end
            end
          end
        end
      end
    end
  end
end
