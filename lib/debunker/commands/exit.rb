class Debunker
  class Command::Exit < Debunker::ClassCommand
    match 'exit'
    group 'Navigating Debunker'
  #'Pop the previous binding.'
    command_options :keep_retval => true

    banner <<-'BANNER'
      Usage:   exit [OPTIONS] [--help]
      Aliases: quit

      Pop the previous binding (does NOT exit program). It can be useful to exit a
      context with a user-provided value. For instance an exit value can be used to
      determine program flow.

      exit "debunker this"
      exit

      https://github.com/debunker/debunker/wiki/State-navigation#wiki-Exit_with_value
    BANNER

    def process
      if _debunker_.binding_stack.one?
        _debunker_.run_command "exit-all #{arg_string}"
      else
        # otherwise just pop a binding and return user supplied value
        process_pop_and_return
      end
    end

    def process_pop_and_return
      popped_object = _debunker_.binding_stack.pop.eval('self')

      # return a user-specified value if given otherwise return the object
      return target.eval(arg_string) unless arg_string.empty?
      popped_object
    end
  end

  Debunker::Commands.add_command(Debunker::Command::Exit)
  #Debunker::Commands.alias_command 'quit', 'exit'
end
