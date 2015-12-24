class Debunker
  class Command::Bang < Debunker::ClassCommand
    match(/^\s*!\s*$/)
    group 'Editing'
  #'Clear the input buffer.'
    command_options :use_prefix => false

    banner <<-'BANNER'
      Clear the input buffer. Useful if the parsing process goes wrong and you get
      stuck in the read loop.
    BANNER

    def process
      output.puts 'Input buffer cleared!'
      eval_string.replace('')
    end
  end

  Debunker::Commands.add_command(Debunker::Command::Bang)
end
