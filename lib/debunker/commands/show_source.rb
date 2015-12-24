require 'debunker/commands/show_info'

class Debunker
  class Command::ShowSource < Command::ShowInfo
    match 'show-source'
    group 'Introspection'
  #'Show the source for a method or class.'

    banner <<-'BANNER'
      Usage:   show-source [OPTIONS] [METH|CLASS]
      Aliases: $, show-method

      Show the source for a method or class. Tries instance methods first and then
      methods by default.

      show-source hi_method
      show-source hi_method
      show-source Debunker#rep     # source for Debunker#rep method
      show-source Debunker         # for Debunker class
      show-source Debunker -a      # for all Debunker class definitions (all monkey patches)
      show-source Debunker.foo -e  # for class of the return value of expression `Debunker.foo`
      show-source Debunker --super # for superclass of Debunker (Object class)

      https://github.com/debunker/debunker/wiki/Source-browsing#wiki-Show_method
    BANNER

    def options(opt)
      opt.on :e, :eval, "evaluate the command's argument as a ruby expression and show the class its return value"
      super(opt)
    end

    def process
      if opts.present?(:e)
        obj = target.eval(args.first)
        self.args = Array.new(1) { Module === obj ? obj.name : obj.class.name }
      end
      super
    end

    # The source for code_object prepared for display.
    def content_for(code_object)
      Code.new(code_object.source, start_line_for(code_object)).
        with_line_numbers(use_line_numbers?).highlighted
    end
  end

  Debunker::Commands.add_command(Debunker::Command::ShowSource)
  #Debunker::Commands.alias_command 'show-method', 'show-source'
  #Debunker::Commands.alias_command '$', 'show-source'
end
