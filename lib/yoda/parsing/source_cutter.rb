module Yoda
  module Parsing
    class SourceCutter
      class CannotRecoverError < StandardError; end

      attr_reader :source, :current_location
      def initialize(source, current_location)
        @source = source
        @current_location = current_location
      end

      # The last point of cut source.
      # @return [Integer]
      def cut_position
        @cut_position ||= current_location_token_range.end_pos - 1
      end

      # @return [::Parser::Source::Range]
      def current_location_token_range
        @current_location_token_range ||= current_location_token.last.last
      end

      # @return [Integer]
      def current_location_token_index
        @current_location_token_index ||= tokens_of_source.find_index { |type, (name, range)| current_location.included?(range) }
      end

      # @return [(Symbol, (String, ::Parser::Source::Range))]
      def current_location_token
        @current_location_token ||= tokens_of_source.find { |type, (name, range)| current_location.included?(range) }
      end

      # @return [Array<(Symbol, (String, ::Parser::Source::Range))>]
      def tokens_of_source
        @tokens_of_source ||= begin
          _, _, tokens = ::Parser::CurrentRuby.new.tokenize(::Parser::Source::Buffer.new("(string)").tap { |b| b.source = source }, true)
          tokens
        end
      end

      # @return [String]
      def cut_source
        @cut_source ||= source.slice(0..cut_position)
      end

      # Returns a source that is made parsable from cut_source.
      # @return [String]
      def error_recovered_source
        @error_recovered_source ||= recover_source
      end

      private

      # @return [String]
      def recover_source
        remained_tokens = tokens_of_source.slice(0..current_location_token_index)
        tokens_to_append = [:tSEMI]

        while
          fixing_source = FixingSource.new(cut_source, tokens_to_append)
          case fixing_source.diagnostic
          when :fix_line
            remained_tokens, tokens_to_append = LineFixer.new.process(remained_tokens, tokens_to_append)
          when :fix_block
            tokens_to_append = BlockFixer.new.process(remained_tokens, tokens_to_append)
            remained_tokens = []
          else
            return fixing_source.to_s
          end
        end
      end

      class FixingSource
        attr_reader :source, :tokens_to_append
        # @param source [String]
        # @param tokens_to_append [Array<Symbol>]
        def initialize(source, tokens_to_append)
          @source = source
          @tokens_to_append = tokens_to_append
        end

        def to_s
          @to_s ||= source + "\n" + tokens_to_append.map(&token_mapper).join("\n")
        end

        def token_mapper
          {
            tSEMI: ';',
            tLBRACE: '{',
            tRBRACE: '}',
            tLPAREN: '(',
            tRPAREN: ')',
            kEND: 'end',
            kNIL: 'nil',
            dummy_constant: 'DUMMY_CONSTANT',
            dummy_method: 'dummy_method',
          }
        end

        # @return [Symbol, nil]
        def diagnostic
          begin
            ::Parser::CurrentRuby.parse(to_s)
            nil
          rescue ::Parser::SyntaxError => ex
            fail CannotRecoverError, "Cannot recover: #{ex.diagnostic.render}" unless ex.diagnostic.reason == :unexpected_token
            fail CannotRecoverError, "Cannot recover: #{ex.diagnostic.render}" unless ex.diagnostic.location.end_pos == to_s.length
            case ex.diagnostic.arguments[:token]
            when 'tSEMI'
              :fix_line
            when '$end'
              :fix_block
            else
              fail CannotRecoverError, "Cannot recover: #{ex.diagnostic.render}"
            end
          end
        end
      end

      class LineFixer
        # @param remained_tokens [Array<(Symbol, (String, ::Parser::Source::Range))>]
        # @param tokens_to_add   [Array<Symbol>]
        def process(remained_tokens, tokens_to_add)
          if tokens_to_add.first == :tSEMI
            token = fix_operator(remained_tokens)
            return [remained_tokens, [token] + tokens_to_add] if token
          end

          fix_inline_block(remained_tokens, tokens_to_add)
        end

        # @return [Symbol, nil]
        def fix_operator(remained_tokens)
          case remained_tokens.last.first
          when :tEQL, :tAMPER2, :tPIPE, :tBANG, :tCARET, :tPLUS, :tMINUS, :tSTAR2, :tDIVIDE, :tPERCENT, :tTILDE, :tCOMMA, :tDOT2, :tDOT3, :tCOLON,
              :tANDOP, :tOROP, :tUMINUS, :tUPLUS, :tTILDE, :tPOW, :tMATCH, :tNMATCH, :tEQ, :tNEQ, :tGT, :tRSHFT, :tGEQ, :tLT, :tLSHFT, :tLEQ, :tASSOC, :tEQQ, :tCMP, :tBANG, :tANDDOT
            :kNIL
          when :tCOLON2
            :dummy_constant
          when :tDOT
            :dummy_method
          else
            nil
          end
        end

        def fix_inline_block(remained_tokens, tokens_to_add)
          stack = []

          remained_tokens.each_with_index.reverse_each do |(token, _), i|
            token_to_add =
              case token
              when :tSTRING_BEG
                reduce(stack, :tSTRING_END)
              when :tSTRING_END
                reduce(stack, :tSTRING_END)
              when :tLBRACE
                reduce(stack, :tRBRACE)
              when :tRBRACE
                next stack.push(:tRBRACE)
              when :tLPAREN, :tLPAREN2
                reduce(stack, :tRPAREN)
              when :tRPAREN, :tRPAREN2
                next stack.push(:tRPAREN)
              else
                nil
              end
            return [remained_tokens.slice(0...i), [token_to_add] + tokens_to_add] if token_to_add
          end

          fail CannotRecoverError, "Cannot fix inline error"
        end

        def reduce(stack, expected)
          if stack.empty?
            expected
          else
            if stack.last == expected
              stack.pop
            else
              fail CannotRecoverError, "Block mismatch in existing source"
            end
            nil
          end
        end
      end

      class BlockFixer
        def process(remained_tokens, tokens_to_add)
          fail CannotRecoverError, "Cannot resolve block error" if remained_tokens.empty?
          stack = []
          tokens_to_add = tokens_to_add.dup

          remained_tokens.each_with_index.reverse_each do |(token, _), i|
            case token
            when :kIF, :kUNLESS, :kWHILE, :kUNTIL, :kCLASS, :kFOR, :kBEGIN, :kCASE, :kCLASS, :kMODULE, :kDEF
              reduce(stack, tokens_to_add, :kEND)
            when :kDO
              next if i > 0 && [:kWHILE, :kUNTIL, :kFOR].include?(remained_tokens[i].first)
              reduce(stack, tokens_to_add, :kEND)
            when :kEND
              stack.push(:kEND)
            when :tLBRACE
              reduce(stack, tokens_to_add, :tRBRACE)
            when :tRBRACE
              stack.push(:tRBRACE)
            end
          end

          fail CannotRecoverError, "Block mismatch in existing source" unless stack.empty?
          tokens_to_add
        end

        def reduce(stack, tokens_to_add, expected)
          if stack.empty?
            tokens_to_add.push(expected)
          else
            if stack.last == expected
              stack.pop
            else
              fail CannotRecoverError, "Block mismatch in existing source"
            end
          end
        end
      end
    end
  end
end
