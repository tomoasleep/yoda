require 'concurrent'
require 'forwardable'

module Yoda
  class Instrument
    class Subscription
      # @return [Instrument]
      attr_reader :instrument

      # @return [String]
      attr_reader :name

      # @return [#call]
      attr_reader :callback

      # @param instrument [Instrument]
      # @param name [String]
      # @param callback [#call]
      def initialize(instrument:, name:, callback:)
        @instrument = instrument
        @name = name
        @callback = callback
      end

      def unsubscribe
        instrument.unsubscribe(self)
      end

      def call(*params, **kwargs)
        callback.call(*params, **kwargs)
      end
    end

    class Progress
      # @return [Integer]
      attr_reader :length, :index

      # @return [#call]
      attr_reader :callback

      # @param length [Integer]
      # @param callback [#call]
      def initialize(length, &callback)
        @length = length
        @index = 0
        @callback = callback
        call
      end

      def increment
        @index += 1
        call
      end

      def call
        callback.call(length: length, index: index)
      end
    end

    # @return [Array<Subscription>]
    attr_reader :subscriptions

    class << self
      extend Forwardable

      delegate %i(hear subscribe emit unsubscribe) => :instance

      # Returns Instrument instance (thread local).
      # @return [Instrument]
      def instance
        local.value
      end

      def clean
        local.value = Instrument.new
      end

      private

      # @return [Concurrent::ThreadLocalVar<Instrument>]
      def local
        @local ||= Concurrent::ThreadLocalVar.new { Instrument.new }
      end
    end

    def initialize
      @subscriptions = []
    end

    # Add subscriptions and eval the given block. these subscriptions are unsubscribed after the block.
    # @param subscription_hash [Hash{ Symbol, String => #call }]
    def hear(subscription_hash = {})
      subscriptions = subscription_hash.map { |key, value| subscribe(key, &value) }
      value = yield
      subscriptions.each(&:unsubscribe)
      value
    end

    # @param name [String, Symbol, nil]
    # @param callback [#call]
    # @return [Subsctiption]
    def subscribe(name, &callback)
      Subscription.new(instrument: self, name: name, callback: callback).tap { |subscription| subscriptions.push(subscription) }
    end

    # @param callback [#call]
    # @return [Subsctiption]
    def subscribe_all(&callback)
      subscribe(nil, &callback)
    end

    # @param name [String]
    # @param params [Hash]
    def emit(name, **params)
      Logger.trace("#{name}: #{params}")
      subscriptions.select { |subscription| subscription.name.nil? || subscription.name === name }.each { |subscription| subscription.call(**params) }
    end

    # @param subscription [Subscription]
    def unsubscribe(subscription)
      subscriptions.delete(subscription)
    end

    # @!group event_name

    # @param phase [Symbol]
    # @param message [String]
    # @param index [Integer, nil]
    # @param length [Integer, nil]
    def initialization_progress(phase:, message:, index: nil, length: nil)
      emit(:initialization_progress, phase: phase, message: message, index: index, length: length)
    end

    # @param index [Integer, nil]
    # @param length [Integer, nil]
    def registry_dump(index: nil, length: nil)
      emit(:registry_dump, index: index, length: length)
    end

    # @param name [String]
    # @param version [String]
    # @param message [String]
    def build_library_registry(message:, name:, version:)
      emit(:build_library_registry, name: name, version: version, message: message)
    end
  end
end
