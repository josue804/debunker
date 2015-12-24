class Debunker
  class Command::ToggleColor < Debunker::ClassCommand
    match 'toggle-color'
    group 'Misc'
  #'Toggle syntax highlighting.'

    banner <<-'BANNER'
      Usage: toggle-color

      Toggle syntax highlighting.
    BANNER

    def process
      _debunker_.color = color_toggle
      output.puts "Syntax highlighting #{_debunker_.color ? "on" : "off"}"
    end

    def color_toggle
      !_debunker_.color
    end

    Debunker::Commands.add_command(self)
  end
end
