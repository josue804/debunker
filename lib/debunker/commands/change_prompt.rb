class Debunker::Command::ChangePrompt < Debunker::ClassCommand
  match 'change-prompt'
  group 'Input and Output'
#'Change the current prompt.'
  command_options argument_required: true
  banner <<-BANNER
    Usage: change-prompt NAME

    Change the current prompt. See list-prompts for a list of available
    prompts.
  BANNER

  def process(prompt)
    if prompt_map.key?(prompt)
      _debunker_.prompt = prompt_map[prompt][:value]
    else
      raise Debunker::CommandError, "'#{prompt}' isn't a known prompt!"
    end
  end

private
  def prompt_map
    Debunker::Prompt::MAP
  end
  Debunker::Commands.add_command(self)
end
