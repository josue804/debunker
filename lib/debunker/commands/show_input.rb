class Debunker
  class Command::ShowInput < Debunker::ClassCommand
    match 'show-input'
    group 'Editing'
  #'Show the contents of the input buffer for the current multi-line expression.'

    banner <<-'BANNER'
      Show the contents of the input buffer for the current multi-line expression.
    BANNER

    def process
      output.puts Code.new(eval_string).with_line_numbers
    end
  end

  Debunker::Commands.add_command(Debunker::Command::ShowInput)
end
