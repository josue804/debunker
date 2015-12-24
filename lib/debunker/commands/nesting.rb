class Debunker
  class Command::Nesting < Debunker::ClassCommand
    match 'nesting'
    group 'Navigating Debunker'
  #'Show nesting information.'

    banner <<-'BANNER'
      Show nesting information.
    BANNER

    def process
      output.puts 'Nesting status:'
      output.puts '--'
      _debunker_.binding_stack.each_with_index do |obj, level|
        if level == 0
          output.puts "#{level}. #{Debunker.view_clip(obj.eval('self'))} (Debunker top level)"
        else
          output.puts "#{level}. #{Debunker.view_clip(obj.eval('self'))}"
        end
      end
    end
  end

  Debunker::Commands.add_command(Debunker::Command::Nesting)
end
