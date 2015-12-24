class Debunker
  class Command::ExitProgram < Debunker::ClassCommand
    match 'exit-program'
    group 'Navigating Debunker'
  #'End the current program.'

    banner <<-'BANNER'
      Usage:   exit-program [--help]
      Aliases: quit-program
               !!!

      End the current program.
    BANNER

    def process
      Kernel.exit target.eval(arg_string).to_i
    end
  end

  Debunker::Commands.add_command(Debunker::Command::ExitProgram)
  #Debunker::Commands.alias_command 'quit-program', 'exit-program'
  #Debunker::Commands.alias_command '!!!', 'exit-program'
end
