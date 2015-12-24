class Debunker
  class Command::ShellMode < Debunker::ClassCommand
    match 'shell-mode'
    group 'Input and Output'
  #'Toggle shell mode. Bring in pwd prompt and file completion.'

    banner <<-'BANNER'
      Toggle shell mode. Bring in pwd prompt and file completion.
    BANNER

    def process
      case _debunker_.prompt
      when Debunker::SHELL_PROMPT
        _debunker_.pop_prompt
        _debunker_.custom_completions = _debunker_.config.file_completions
      else
        _debunker_.push_prompt Debunker::SHELL_PROMPT
        _debunker_.custom_completions = _debunker_.config.command_completions
      end
    end
  end

  Debunker::Commands.add_command(Debunker::Command::ShellMode)
  #Debunker::Commands.alias_command 'file-mode', 'shell-mode'
end
