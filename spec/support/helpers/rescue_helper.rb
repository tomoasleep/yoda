require 'debug'

module RescueHelper
  def self.rescue
    yield
  rescue => e
    self.rescued(e)
    raise e
  end

  # @param e [StandardError]
  def self.rescued(e)
    puts "Rescued: #{e.inspect}"
    puts e.backtrace.map { |b| "\t#{b}" }
    puts "\n"

    DEBUGGER__::SESSION.enter_postmortem_session(e)

    # if bindings = e.instance_variable_get(:@rescue_helper_bindings)
    #   # Although we provide irb other bindings than current binding, debug command in irb uses the current binding.
    #   # bindings.first.irb
    # end
  end

  def self.enable!
    DEBUGGER__::SESSION.postmortem = true

    # @trace_point ||= TracePoint.new(:raise) do |tp|
    #   exception = tp.raised_exception
    #   bindings = tp.binding.respond_to?(:callers) ? tp.binding.callers : [tp.binding]

    #   unless exception.instance_variable_defined?(:@rescue_helper_bindings)
    #     exception.instance_variable_set(:@rescue_helper_bindings, bindings)
    #     exception.instance_variable_set(:@rescue_helper_cause, $!)
    #   end
    # end

    # @trace_point.enable
  end

  module RSpec
    def self.run(example)
      RescueHelper.rescue do
        example.run
      end
    end

    def self.after(example)
      e = example.exception
      RescueHelper.rescued(e) if e
    end
  end
end

if ENV['RESCUE_DEBUG']
  RescueHelper.enable!

  RSpec.configure do |c|
    c.around(:each) do |example|
      RescueHelper::RSpec.run(example)
    end

    c.after(:each) do |example|
      RescueHelper::RSpec.after(example)
    end
  end
end
