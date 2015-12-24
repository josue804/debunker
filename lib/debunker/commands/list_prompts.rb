class Debunker::Command::ListPrompts < Debunker::ClassCommand
  match 'list-prompts'
  group 'Input and Output'
#'List the prompts available for use.'
  banner <<-BANNER
    Usage: list-prompts

    List the available prompts. You can use change-prompt to switch between
    them.
  BANNER

  def process
    output.puts heading("Available prompts") + "\n"
    prompt_map.each do |name, prompt|
      output.write "Name: #{text.bold(name)}"
      output.puts selected_prompt?(prompt) ? selected_text : ""
      output.puts prompt[:description]
      output.puts
    end
  end

private
  def prompt_map
    Debunker::Prompt::MAP
  end

  def selected_text
    text.red " (selected) "
  end

  def selected_prompt?(prompt)
    _debunker_.prompt == prompt[:value]
  end
  Debunker::Commands.add_command(self)
end