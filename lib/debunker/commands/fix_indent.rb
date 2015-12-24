class Debunker
  class Command::FixIndent < Debunker::ClassCommand
    match 'fix-indent'
    group 'Input and Output'

  #"Correct the indentation for contents of the input buffer"

    banner <<-USAGE
      Usage: fix-indent
    USAGE

    def process
      indented_str = Debunker::Indent.indent(eval_string)
      eval_string.replace indented_str
    end
  end

  Debunker::Commands.add_command(Debunker::Command::FixIndent)
end
