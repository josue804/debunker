class Debunker
  class Command::Reset < Debunker::ClassCommand
    match 'reset'
    group 'The only command you need, amirite'
  #'Reset the REPL to a clean state.'

    banner <<-'BANNER'
      Reset the REPL to a clean state.
    BANNER

    def process
      output.puts 'Debunker reset.'
      exec 'debunker'
    end
  end

  Debunker::Commands.add_command(Debunker::Command::Reset)
end
