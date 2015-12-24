class Debunker
  class Command::SwitchTo < Debunker::ClassCommand
    match 'switch-to'
    group 'Navigating Debunker'
  #'Start a new subsession on a binding in the current stack.'

    banner <<-'BANNER'
      Start a new subsession on a binding in the current stack (numbered by nesting).
    BANNER

    def process(selection)
      selection = selection.to_i

      if selection < 0 || selection > _debunker_.binding_stack.size - 1
        raise CommandError, "Invalid binding index #{selection} - use `nesting` command to view valid indices."
      else
        Debunker.start(_debunker_.binding_stack[selection])
      end
    end
  end

  Debunker::Commands.add_command(Debunker::Command::SwitchTo)
end
