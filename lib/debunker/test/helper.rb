require 'debunker'

# in case the tests call reset_defaults, ensure we reset them to
# amended (test friendly) values
class << Debunker
  alias_method :orig_reset_defaults, :reset_defaults
  def reset_defaults
    orig_reset_defaults

    Debunker.config.color = false
    Debunker.config.pager = false
    Debunker.config.should_load_rc      = false
    Debunker.config.should_load_local_rc= false
    Debunker.config.should_load_plugins = false
    Debunker.config.history.should_load = false
    Debunker.config.history.should_save = false
    Debunker.config.correct_indent      = false
    Debunker.config.hooks               = Debunker::Hooks.new
    Debunker.config.collision_warning   = false
  end
end
Debunker.reset_defaults

# A global space for storing temporary state during tests.

module DebunkerTestHelpers

  module_function

  # inject a variable into a binding
  def inject_var(name, value, b)
    Debunker.current[:debunker_local] = value
    b.eval("#{name} = ::Debunker.current[:debunker_local]")
  ensure
    Debunker.current[:debunker_local] = nil
  end

  def constant_scope(*names)
    names.each do |name|
      Object.remove_const name if Object.const_defined?(name)
    end

    yield
  ensure
    names.each do |name|
      Object.remove_const name if Object.const_defined?(name)
    end
  end

  # Open a temp file and yield it to the block, closing it after
  # @return [String] The path of the temp file
  def temp_file(ext='.rb')
    file = Tempfile.new(['debunker', ext])
    yield file
  ensure
    file.close(true) if file
    File.unlink("#{file.path}c") if File.exist?("#{file.path}c") # rbx
  end

  def unindent(*args)
    Debunker::Helpers::CommandHelpers.unindent(*args)
  end

  def mock_command(cmd, args=[], opts={})
    output = StringIO.new
    debunker = Debunker.new(output: output)
    ret = cmd.new(opts.merge(debunker_instance: debunker, :output => output)).call_safely(*args)
    Struct.new(:output, :return).new(output.string, ret)
  end

  def mock_exception(*mock_backtrace)
    StandardError.new.tap do |e|
      e.define_singleton_method(:backtrace) { mock_backtrace }
    end
  end

  def inner_scope
    catch(:inner_scope) do
      yield ->{ throw(:inner_scope, self) }
    end
  end
end

def debunker_tester(*args, &block)
  if args.length == 0 || args[0].is_a?(Hash)
    args.unshift(Debunker.toplevel_binding)
  end

  DebunkerTester.new(*args).tap do |t|
    (class << t; self; end).class_eval(&block) if block
  end
end

def debunker_eval(*eval_strs)
  if eval_strs.first.is_a? String
    binding = Debunker.toplevel_binding
  else
    binding = Debunker.binding_for(eval_strs.shift)
  end

  debunker_tester(binding).eval(*eval_strs)
end

class DebunkerTester
  extend Forwardable

  attr_reader :debunker, :out

  def_delegators :@debunker, :eval_string, :eval_string=

  def initialize(target = TOPLEVEL_BINDING, options = {})
    @debunker = Debunker.new(options.merge(:target => target))
    @history = options[:history]

    @debunker.inject_sticky_locals!
    reset_output
  end

  def eval(*strs)
    reset_output
    result = nil

    strs.flatten.each do |str|
      # Check for space prefix. See #1369.
      if str !~ /^\s\S/
        str = "#{str.strip}\n"
      end
      @history.push str if @history

      if @debunker.process_command(str)
        result = last_command_result_or_output
      else
        result = @debunker.evaluate_ruby(str)
      end
    end

    result
  end

  def push(*lines)
    Array(lines).flatten.each do |line|
      @debunker.eval(line)
    end
  end

  def push_binding(context)
    @debunker.push_binding context
  end

  def last_output
    @out.string if @out
  end

  def process_command(command_str)
    @debunker.process_command(command_str) or raise "Not a valid command"
    last_command_result_or_output
  end

  def last_command_result
    result = Debunker.current[:debunker_cmd_result]
    result.retval if result
  end

  protected

  def last_command_result_or_output
    result = last_command_result
    if result != Debunker::Command::VOID_VALUE
      result
    else
      last_output
    end
  end

  def reset_output
    @out = StringIO.new
    @debunker.output = @out
  end
end
