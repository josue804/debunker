class Debunker
  class Command::DisableDebunker < Debunker::ClassCommand
    match 'disable-debunker'
    group 'Navigating Debunker'
  #'Stops all future calls to debunker and exits the current session.'

    banner <<-'BANNER'
      Usage: disable-debunker

      After this command is run any further calls to debunker will immediately return `nil`
      without interrupting the flow of your program. This is particularly useful when
      you've debugged the problem you were having, and now wish the program to run to
      the end.

      As alternatives, consider using `exit!` to force the current Ruby process
      to quit immediately; or using `edit-method -p` to remove the `binding.debunker`
      from the code.
    BANNER

    def process
      ENV['DISABLE_PRY'] = 'true'
      _debunker_.run_command "exit"
    end
  end

  Debunker::Commands.add_command(Debunker::Command::DisableDebunker)
end
