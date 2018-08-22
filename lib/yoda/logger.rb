require 'forwardable'

module Yoda
  class Logger
    LOG_LEVELS = %i(debug info warn error fatal).freeze

    class << self
      extend Forwardable
      def_delegators :instance, *%i(pipeline debug info warn error fatal log_level allow_debug? allow_info? allow_warn? allow_error? allow_fatal? log_level=)

      # @return [Yoda::Logger]
      def instance
        @instance ||= Yoda::Logger.new(STDERR)
      end

      # @!macro [attach]
      #   @!method $1(content, tag: nil)
      #     @param content [String]
      #     @param tag [String, nil]
      #   @!method allow_$1?
      #     @return [true, false]
      def define_logging_method(level)
        define_method(level) do |content, tag: nil|
          return unless public_send("allow_#{level}?")
          prefix = "[#{level}]#{tag ? ' (' + tag + ')' : '' } "
          io.puts(prefix + content.to_s.split("\n").join(prefix))
        end

        define_method("allow_#{level}?") do
          allowed_log_levels.include?(level)
        end
      end
    end

    # @return [IO]
    attr_accessor :io

    # @return [Hash<Thread>]
    attr_reader :threads

    # @return [Symbol]
    attr_accessor :log_level

    LOG_LEVELS.each { |level| define_logging_method(level) }

    def initialize(io)
      @io = io
      @threads = {}
      @log_level = :info
    end

    def allowed_log_levels
      LOG_LEVELS.drop_while { |level| level != log_level }
    end

    def pipeline(tag:)
      threads[tag] ||= begin
        r, w = IO.pipe
        Thread.new do
          r.each do |content|
            debug(content.chomp, tag: tag)
          end
        end
        w
      end
    end
  end
end
