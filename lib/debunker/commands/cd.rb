class Debunker
  class Command::Cd < Debunker::ClassCommand
    match 'cd'
    group 'The only command you need, amirite'
  #'Move into a new context (object or scope).'

    banner <<-'BANNER'
      Usage: cd [OPTIONS] [--help]

      Move into new context (object or scope). As in UNIX shells use `cd ..` to go
      back, `cd /` to return to Debunker top-level and `cd -` to toggle between last two
      scopes. Complex syntax (e.g `cd ../@x/@y`) also supported.

      cd @x
      cd ..
      cd /
      cd -

      https://github.com/debunker/debunker/wiki/State-navigation#wiki-Changing_scope
    BANNER

    def process
      state.old_stack ||= []

      if arg_string.strip == "-"
        unless state.old_stack.empty?
          _debunker_.binding_stack, state.old_stack = state.old_stack, _debunker_.binding_stack
        end
      else
        stack = ObjectPath.new(arg_string, _debunker_.binding_stack).resolve

        if stack && stack != _debunker_.binding_stack
          state.old_stack = _debunker_.binding_stack
          _debunker_.binding_stack = stack
        end
      end
    end
  end

  Debunker::Commands.add_command(Debunker::Command::Cd)
end
