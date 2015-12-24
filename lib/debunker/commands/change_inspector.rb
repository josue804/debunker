class Debunker::Command::ChangeInspector < Debunker::ClassCommand
  match 'change-inspector'
  group 'Input and Output'
#'Change the current inspector proc.'
  command_options argument_required: true
  banner <<-BANNER
    Usage: change-inspector NAME

    Change the proc used to print return values. See list-inspectors for a list
    of available procs and a short description of what each one does.
  BANNER

  def process(inspector)
    if inspector_map.key?(inspector)
      _debunker_.print = inspector_map[inspector][:value]
      output.puts "Switched to the '#{inspector}' inspector!"
    else
      raise Debunker::CommandError, "'#{inspector}' isn't a known inspector!"
    end
  end

private
  def inspector_map
    Debunker::Inspector::MAP
  end
  Debunker::Commands.add_command(self)
end
