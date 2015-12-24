class Debunker
  class Command::BangDebunker < Debunker::ClassCommand
    match '!debunker'
    group 'Navigating Debunker'
  #'Start a Debunker session on current self.'

    banner <<-'BANNER'
      Start a Debunker session on current self. Also works mid multi-line expression.
    BANNER

    def process
      target.debunker
    end
  end

  Debunker::Commands.add_command(Debunker::Command::BangDebunker)
end
