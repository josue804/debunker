class Debunker
  class Command::Cat < Debunker::ClassCommand
    require 'debunker/commands/cat/abstract_formatter.rb'
    require 'debunker/commands/cat/input_expression_formatter.rb'
    require 'debunker/commands/cat/exception_formatter.rb'
    require 'debunker/commands/cat/file_formatter.rb'

    match 'cat'
    group 'Input and Output'
  #"Show code from a file, Debunker's input buffer, or the last exception."

    banner <<-'BANNER'
      Usage: cat FILE
             cat --ex [STACK_INDEX]
             cat --in [INPUT_INDEX_OR_RANGE]

      `cat` is capable of showing part or all of a source file, the context of the
      last exception, or an expression from Debunker's input history.

      `cat --ex` defaults to showing the lines surrounding the location of the last
      exception. Invoking it more than once travels up the exception's backtrace, and
      providing a number shows the context of the given index of the backtrace.
    BANNER

    def options(opt)
      opt.on :ex,        "Show the context of the last exception", :optional_argument => true, :as => Integer
      opt.on :i, :in,    "Show one or more entries from Debunker's expression history", :optional_argument => true, :as => Range, :default => -5..-1
      opt.on :s, :start, "Starting line (defaults to the first line)", :optional_argument => true, :as => Integer
      opt.on :e, :end,   "Ending line (defaults to the last line)", :optional_argument => true, :as => Integer
      opt.on :l, :'line-numbers', "Show line numbers"
      opt.on :t, :type,  "The file type for syntax highlighting (e.g., 'ruby' or 'python')", :argument => true, :as => Symbol
    end

    def process
      output = case
               when opts.present?(:ex)
                 ExceptionFormatter.new(_debunker_.last_exception, _debunker_, opts).format
               when opts.present?(:in)
                 InputExpressionFormatter.new(_debunker_.input_array, opts).format
               else
                 FileFormatter.new(args.first, _debunker_, opts).format
               end

      _debunker_.pager.page output
    end

    def complete(search)
      super | load_path_completions
    end

    def load_path_completions
      $LOAD_PATH.flat_map do |path|
        Dir[path + '/**/*'].map { |f|
          next if File.directory?(f)
          f.sub!(path + '/', '')
        }
      end
    end
  end

  Debunker::Commands.add_command(Debunker::Command::Cat)
end
