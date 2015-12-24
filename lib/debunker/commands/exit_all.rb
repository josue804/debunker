class Debunker
  class Command::ExitAll < Debunker::ClassCommand
    match 'exit-all'
    group 'Navigating Debunker'
  #'End the current Debunker session.'

    banner <<-'BANNER'
      Usage:   exit-all [--help]
      Aliases: !!@

      End the current Debunker session (popping all bindings and returning to caller).
      Accepts optional return value.
    BANNER

    def process
      # calculate user-given value
      exit_value = target.eval(arg_string)

      # clear the binding stack
      _debunker_.binding_stack.clear

      # break out of the repl loop
      throw(:breakout, exit_value)
    end
  end

  Debunker::Commands.add_command(Debunker::Command::ExitAll)
  #Debunker::Commands.alias_command '!!@', 'exit-all'
end
