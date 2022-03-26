require 'set'

module Yoda
  class IdMask
    # @return [Hash<Symbol>, nil]
    attr_reader :pattern

    # @param pattern [IdMask, Set<Symbol>, Array<Symbol>, Hash<Symbol>, nil]
    # @return [IdMask]
    def self.build(pattern)
      if pattern.is_a?(IdMask)
        pattern
      elsif pattern.nil?
        new(pattern)
      elsif pattern.is_a?(Hash)
        new(pattern.map { |k, v| [k.to_sym, v] }.to_h)
      else
        new(pattern.to_a.to_h { |id| [id.to_sym, nil] })
      end
    end

    # @param pattern [Hash<Symbol>, nil]
    def initialize(pattern)
      fail TypeError, "pattern must be a Hash or nil" unless pattern.is_a?(Hash) || pattern.nil?
      @pattern = pattern
    end

    # @param id [Symbol, String]
    # @return [Boolean]
    def cover?(id)
      return true if any?
      pattern.has_key?(id.to_sym)
    end

    # @param another [IdMasklia, Set<Symbol>, Array<Symbol>, Hash<Symbol>, nil]
    # @return [IdMask]
    def intersection(another)
      another_mask = IdMask.build(another)
      return another_mask if any?
      return self if another_mask.any?

      ids_intersection = covering_ids & another_mask.covering_ids

      intersection_pattern = ids_intersection.map do |id|
        [id, nesting_mask(id) & another_mask.nesting_mask(id)]
      end.to_h

      IdMask.build(intersection_pattern)
    end

    alias_method :&, :intersection

    # @return [Boolean]
    def any?
      pattern.nil?
    end

    # @return [Set<Symbol>, nil]
    def covering_ids
      @covering_ids ||= begin
        if any?
          nil
        else 
          Set.new(pattern.keys)
        end
      end
    end

    # @param id [String, Symbol]
    # @return [IdMask]
    def nesting_mask(id)
      if pattern.is_a?(Hash)
        IdMask.build(pattern[id.to_sym])
      else
        IdMask.build(nil)
      end
    end

    # @return [Hash, nil]
    def to_pattern
      pattern&.map { |k, v| [k, v&.to_pattern] }&.to_h
    end
  end
end
