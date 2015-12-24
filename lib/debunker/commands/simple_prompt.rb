class Debunker
  class Command::SimplePrompt < Debunker::ClassCommand
    match 'simple-prompt'
    group 'prompts'
  #'Toggle the simple prompt.'

    banner <<-'BANNER'
      Toggle the simple prompt.
    BANNER

    def process
      case _debunker_.prompt
      when Debunker::SIMPLE_PROMPT
        _debunker_.pop_prompt
      else
        _debunker_.push_prompt Debunker::SIMPLE_PROMPT
      end
    end
  end

  Debunker::Commands.add_command(Debunker::Command::SimplePrompt)
end
