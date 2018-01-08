require 'parser/current'

module Yoda
  module Parsing
    class Parser
      # @param string [String]
      # @return [::Parser::AST::Node]
      def parse(string)
        ::Parser::CurrentRuby.parse(string)
      end
    end
  end
end
