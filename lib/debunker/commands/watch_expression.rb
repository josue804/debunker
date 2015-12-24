class Debunker
  class Command::WatchExpression < Debunker::ClassCommand
    require 'debunker/commands/watch_expression/expression.rb'

    match 'watch'
    group 'The only command you need, amirite'
  #'Watch the value of an expression and print a notification whenever it changes.'
    command_options :use_prefix => false

    banner <<-'BANNER'
      Usage: watch [EXPRESSION]
             watch
             watch --delete [INDEX]

      watch [EXPRESSION] adds an expression to the list of those being watched.
      It will be re-evaluated every time you hit enter in debunker. If its value has
      changed, the new value will be printed to the console.

      This is useful if you are step-through debugging and want to see how
      something changes over time.  It's also useful if you're trying to write
      a method inside debunker and want to check that it gives the right answers
      every time you redefine it.

      watch on its own displays all the currently watched expressions and their
      values, and watch --delete [INDEX] allows you to delete expressions from
      the list being watched.
    BANNER

    def options(opt)
      opt.on :d, :delete,
        "Delete the watch expression with the given index. If no index is given; clear all watch expressions.",
        :optional_argument => true, :as => Integer
      opt.on :l, :list,
        "Show all current watch expressions and their values.  Calling watch with no expressions or options will also show the watch expressions."
    end

    def process
      case
      when opts.present?(:delete)
        delete opts[:delete]
      when opts.present?(:list) || args.empty?
        list
      else
        add_hook
        add_expression(args)
      end
    end

    private

    def expressions
      _debunker_.config.watch_expressions ||= []
    end

    def delete(index)
      if index
        output.puts "Deleting watch expression ##{index}: #{expressions[index-1]}"
        expressions.delete_at(index-1)
      else
        output.puts "Deleting all watched expressions"
        expressions.clear
      end
    end

    def list
      if expressions.empty?
        output.puts "No watched expressions"
      else
        _debunker_.pager.open do |pager|
          pager.puts "Listing all watched expressions:"
          pager.puts ""
          expressions.each_with_index do |expr, index|
            pager.print text.with_line_numbers(expr.to_s, index+1)
          end
          pager.puts ""
        end
      end
    end

    def eval_and_print_changed(output)
      expressions.each do |expr|
        expr.eval!
        if expr.changed?
          output.puts "#{text.blue "watch"}: #{expr.to_s}"
        end
      end
    end

    def add_expression(arguments)
      expressions << Expression.new(_debunker_, target, arg_string)
      output.puts "Watching #{Code.new(arg_string).highlighted}"
    end

    def add_hook
      hook = [:after_eval, :watch_expression]
      unless _debunker_.hooks.hook_exists?(*hook)
        _debunker_.hooks.add_hook(*hook) do |_, _debunker_|
          eval_and_print_changed _debunker_.output
        end
      end
    end
  end

  Debunker::Commands.add_command(Debunker::Command::WatchExpression)
end
