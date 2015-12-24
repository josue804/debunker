class Debunker

  # A class to manage the loading of files through the REPL loop.
  # This is an interesting trick as it processes your file as if it
  # was user input in an interactive session. As a result, all Debunker
  # commands are available, and they are executed non-interactively. Furthermore
  # the session becomes interactive when the repl loop processes a
  # 'make-interactive' command in the file. The session also becomes
  # interactive when an exception is encountered, enabling you to fix
  # the error before returning to non-interactive processing with the
  # 'make-non-interactive' command.

  class REPLFileLoader
    def initialize(file_name)
      full_name = File.expand_path(file_name)
      raise RuntimeError, "No such file: #{full_name}" if !File.exist?(full_name)

      define_additional_commands
      @content = File.read(full_name)
    end

    # Switch to interactive mode, i.e take input from the user
    # and use the regular print and exception handlers.
    # @param [Debunker] _debunker_ the Debunker instance to make interactive.
    def interactive_mode(_debunker_)
      _debunker_.config.input = Debunker.config.input
      _debunker_.config.print = Debunker.config.print
      _debunker_.config.exception_handler = Debunker.config.exception_handler
      Debunker::REPL.new(_debunker_).start
    end

    # Switch to non-interactive mode. Essentially
    # this means there is no result output
    # and that the session becomes interactive when an exception is encountered.
    # @param [Debunker] _debunker_ the Debunker instance to make non-interactive.
    def non_interactive_mode(_debunker_, content)
      _debunker_.print = proc {}
      _debunker_.exception_handler = proc do |o, e, _p_|
        _p_.run_command "cat --ex"
        o.puts "...exception encountered, going interactive!"
        interactive_mode(_debunker_)
      end

      content.lines.each do |line|
        break unless _debunker_.eval line, :generated => true
      end

      unless _debunker_.eval_string.empty?
        _debunker_.output.puts "#{_debunker_.eval_string}...exception encountered, going interactive!"
        interactive_mode(_debunker_)
      end
    end

    # Define a few extra commands useful for flipping back & forth
    # between interactive/non-interactive modes
    def define_additional_commands
      s = self

      Debunker::Commands.command "make-interactive", "Make the session interactive" do
        s.interactive_mode(_debunker_)
      end

      Debunker::Commands.command "load-file", "Load another file through the repl" do |file_name|
        s.non_interactive_mode(_debunker_, File.read(File.expand_path(file_name)))
      end
    end

    # Actually load the file through the REPL by setting file content
    # as the REPL input stream.
    def load
      non_interactive_mode(Debunker.new, @content)
    end
  end
end
