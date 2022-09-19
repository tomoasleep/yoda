require 'json'

module Yoda
  module Store
    module Actions
      class ActionProcessRunner
        # @return [Enumerable<Objects::Patch>]
        # @yieldreturn [Enumerable<Objects::Patch>]
        def run(&block)
          read_pipe, write_pipe = IO.pipe

          if Yoda.inline_process?
            begin
              patches = block.call
              t = Thread.new do
                Transceiver.new(write_pipe).emit(patches)
                write_pipe.close
              end
              Transceiver.new(read_pipe).receive
            ensure
              t.join if t
            end
          else
            child_pid = Yoda.fork_process do
              read_pipe.close
              Transceiver.new(write_pipe).emit(block.call)
            ensure
              write_pipe.close
            end

            write_pipe.close
            Transceiver.new(read_pipe).receive
          end
        ensure
          if child_pid
            _, status = Process.waitpid2(child_pid)
            fail ImportError unless status.success?
          end
        end

        module Mixin
          # @return [Enumerable<Objects::Patch>]
          def run_process
            ActionProcessRunner.new.run { run }
          end

          # @abstract
          # @return [Enumerable<Objects::Patch>]
          def run
            fail NotImplementedError
          end
        end

        class Transceiver
          # @return [IO]
          attr_reader :io

          # @param io [IO]
          def initialize(io)
            @io = io
          end

          # @param patches [Enumerable<Objects::Patch>]
          # @return [void]
          def emit(patches)
            patches.each do |patch|
              io.puts(patch.id.dump)
              io.puts(patch.keys.length)
              patch.keys.each do |key|
                io.puts(patch.get(key).to_json.dump)
              end
            end
          end

          # @return [Enumerable<Store::Objects::Patch>]
          def receive
            patches = []
            while id = io.gets(chomp: true)&.undump
              patch = Store::Objects::Patch.new(id)
              item_length = io.gets.to_i

              item_length.times do
                content = io.gets(chomp: true).undump
                patch.register(JSON.load(content, symbolize_names: true))
              end

              patches << patch
            end
            patches
          end
        end
      end
    end
  end
end
