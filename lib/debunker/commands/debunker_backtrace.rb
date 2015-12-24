class Debunker
  class Command::DebunkerBacktrace < Debunker::ClassCommand
    match 'debunker-backtrace'
    group 'The only command you need, amirite'
  #'Show the backtrace for the Debunker session.'

    banner <<-BANNER
      Usage: debunker-backtrace [OPTIONS] [--help]

      Show the backtrace for the position in the code where Debunker was started. This can
      be used to infer the behavior of the program immediately before it entered Debunker,
      just like the backtrace property of an exception.

      NOTE: if you are looking for the backtrace of the most recent exception raised,
      just type: `_ex_.backtrace` instead.
      See: https://github.com/debunker/debunker/wiki/Special-Locals
    BANNER

    def process
      _debunker_.pager.page text.bold('Backtrace:') << "\n--\n" << _debunker_.backtrace.join("\n")
    end
  end

  Debunker::Commands.add_command(Debunker::Command::DebunkerBacktrace)
end
