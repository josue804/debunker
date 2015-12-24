require 'forwardable'

class Debunker
  class REPL
    extend Forwardable
    def_delegators :@debunker, :input, :output

    # @return [Debunker] The instance of {Debunker} that the user is controlling.
    attr_accessor :debunker

    # Instantiate a new {Debunker} instance with the given options, then start a
    # {REPL} instance wrapping it.
    # @option options See {Debunker#initialize}
    def self.start(options)
      new(Debunker.new(options)).start
    end

    # Create an instance of {REPL} wrapping the given {Debunker}.
    # @param [Debunker] debunker The instance of {Debunker} that this {REPL} will control.
    # @param [Hash] options Options for this {REPL} instance.
    # @option options [Object] :target The initial target of the session.
    def initialize(debunker, options = {})
      @debunker    = debunker
      @indent = Debunker::Indent.new

      @readline_output = nil

      if options[:target]
        @debunker.push_binding options[:target]
      end
    end

    # Start the read-eval-print loop.
    # @return [Object?] If the session throws `:breakout`, return the value
    #   thrown with it.
    # @raise [Exception] If the session throws `:raise_up`, raise the exception
    #   thrown with it.
    def start
      prologue
      Debunker::InputLock.for(:all).with_ownership { repl }
    ensure
      epilogue
    end

    private

    # Set up the repl session.
    # @return [void]
    def prologue
      debunker.exec_hook :before_session, debunker.output, debunker.current_binding, debunker

      # Clear the line before starting Debunker. This fixes issue #566.
      if debunker.config.correct_indent
        Kernel.print Debunker::Helpers::BaseHelpers.windows_ansi? ? "\e[0F" : "\e[0G"
      end
    end

    # The actual read-eval-print loop.
    #
    # The {REPL} instance is responsible for reading and looping, whereas the
    # {Debunker} instance is responsible for evaluating user input and printing
    # return values and command output.
    #
    # @return [Object?] If the session throws `:breakout`, return the value
    #   thrown with it.
    # @raise [Exception] If the session throws `:raise_up`, raise the exception
    #   thrown with it.
    def repl
      loop do
        case val = read
        when :control_c
          output.puts ""
          debunker.reset_eval_string
        when :no_more_input
          output.puts "" if output.tty?
          break
        else
          output.puts "" if val.nil? && output.tty?
          return debunker.exit_value unless debunker.eval(val)
        end
      end
    end

    # Clean up after the repl session.
    # @return [void]
    def epilogue
      debunker.exec_hook :after_session, debunker.output, debunker.current_binding, debunker
    end

    # Read a line of input from the user.
    # @return [String] The line entered by the user.
    # @return [nil] On `<Ctrl-D>`.
    # @return [:control_c] On `<Ctrl+C>`.
    # @return [:no_more_input] On EOF.
    def read
      @indent.reset if debunker.eval_string.empty?
      current_prompt = debunker.select_prompt
      indentation = debunker.config.auto_indent ? @indent.current_prefix : ''

      val = read_line("#{current_prompt}#{indentation}")

      # Return nil for EOF, :no_more_input for error, or :control_c for <Ctrl-C>
      return val unless String === val

      if debunker.config.auto_indent
        original_val = "#{indentation}#{val}"
        indented_val = @indent.indent(val)

        if output.tty? && debunker.config.correct_indent && Debunker::Helpers::BaseHelpers.use_ansi_codes?
          output.print @indent.correct_indentation(
            current_prompt, indented_val,
            original_val.length - indented_val.length
          )
          output.flush
        end
      else
        indented_val = val
      end

      indented_val
    end

    # Manage switching of input objects on encountering `EOFError`s.
    # @return [Object] Whatever the given block returns.
    # @return [:no_more_input] Indicates that no more input can be read.
    def handle_read_errors
      should_retry = true
      exception_count = 0

      begin
        yield
      rescue EOFError
        debunker.config.input = Debunker.config.input
        if !should_retry
          output.puts "Error: Debunker ran out of things to read from! " \
            "Attempting to break out of REPL."
          return :no_more_input
        end
        should_retry = false
        retry

      # Handle <Ctrl+C> like Bash: empty the current input buffer, but don't
      # quit.  This is only for MRI 1.9; other versions of Ruby don't let you
      # send Interrupt from within Readline.
      rescue Interrupt
        return :control_c

      # If we get a random error when trying to read a line we don't want to
      # automatically retry, as the user will see a lot of error messages
      # scroll past and be unable to do anything about it.
      rescue RescuableException => e
        puts "Error: #{e.message}"
        output.puts e.backtrace
        exception_count += 1
        if exception_count < 5
          retry
        end
        puts "FATAL: Debunker failed to get user input using `#{input}`."
        puts "To fix this you may be able to pass input and output file " \
          "descriptors to debunker directly. e.g."
        puts "  Debunker.config.input = STDIN"
        puts "  Debunker.config.output = STDOUT"
        puts "  binding.debunker"
        return :no_more_input
      end
    end

    # Returns the next line of input to be sent to the {Debunker} instance.
    # @param [String] current_prompt The prompt to use for input.
    # @return [String?] The next line of input, or `nil` on <Ctrl-D>.
    def read_line(current_prompt)
      handle_read_errors do
        if coolline_available?
          input.completion_proc = proc do |cool|
            completions = @debunker.complete cool.completed_word
            completions.compact
          end
        elsif input.respond_to? :completion_proc=
          input.completion_proc = proc do |inp|
            @debunker.complete inp
          end
        end

        if readline_available?
          set_readline_output
          input_readline(current_prompt, false) # false since we'll add it manually
        elsif coolline_available?
          input_readline(current_prompt)
        else
          if input.method(:readline).arity == 1
            input_readline(current_prompt)
          else
            input_readline
          end
        end
      end
    end

    def input_readline(*args)
      Debunker::InputLock.for(:all).interruptible_region do
        input.readline(*args)
      end
    end

    def readline_available?
      defined?(Readline) && input == Readline
    end

    def coolline_available?
      defined?(Coolline) && input.is_a?(Coolline)
    end

    # If `$stdout` is not a tty, it's probably a pipe.
    # @example
    #   #Alias for `piping?` returns `false`
    #   % debunker
    #   [1] debunker(main)
    #
    #   #Alias for `piping?` returns `true`
    #   % debunker | tee log
    def piping?
      return false unless $stdout.respond_to?(:tty?)
      !$stdout.tty? && $stdin.tty? && !Debunker::Helpers::BaseHelpers.windows?
    end

    # @return [void]
    def set_readline_output
      return if @readline_output
      if piping?
        @readline_output = (Readline.output = Debunker.config.output)
      end
    end
  end
end