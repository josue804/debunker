class Debunker
  class Command::ImportSet < Debunker::ClassCommand
    match 'import-set'
    group 'Commands'
    # TODO: Provide a better description with examples and a general conception
    # of this command.
  #'Import a Debunker command set.'

    banner <<-'BANNER'
      Import a Debunker command set.
    BANNER

    def process(command_set_name)
      raise CommandError, "Provide a command set name" if command_set.nil?

      set = target.eval(arg_string)
      _debunker_.commands.import set
    end
  end

  Debunker::Commands.add_command(Debunker::Command::ImportSet)
end
