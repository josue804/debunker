class Debunker
  class Command::GemOpen < Debunker::ClassCommand
    match 'gem-open'
    group 'Gems'
  #'Opens the working directory of the gem in your editor.'
    command_options :argument_required => true

    banner <<-'BANNER'
      Usage: gem-open GEM_NAME

      Change the current working directory to that in which the given gem is
      installed, and then opens your text editor.

      gem-open debunker-exception_explorer
    BANNER

    def process(gem)
      Dir.chdir(Rubygem.spec(gem).full_gem_path) do
        Debunker::Editor.new(_debunker_).invoke_editor(".", 0, false)
      end
    end

    def complete(str)
      Rubygem.complete(str)
    end
  end

  Debunker::Commands.add_command(Debunker::Command::GemOpen)
end
