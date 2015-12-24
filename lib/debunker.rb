# (C) John Mair (banisterfiend) 2015
# MIT License
#
require 'pp'

require 'debunker/input_lock'
require 'debunker/exceptions'
require 'debunker/helpers/base_helpers'
require 'debunker/hooks'
require 'forwardable'

class Debunker
  # The default hooks - display messages when beginning and ending Debunker sessions.
  DEFAULT_HOOKS = Debunker::Hooks.new.add_hook(:before_session, :default) do |out, target, _debunker_|
    next if _debunker_.quiet?
    _debunker_.run_command("whereami --quiet")
  end

  # The default print
  DEFAULT_PRINT = proc do |output, value, _debunker_|
    _debunker_.pager.open do |pager|
      pager.print _debunker_.config.output_prefix
      Debunker::ColorPrinter.pp(value, pager, Debunker::Terminal.width! - 1)
    end
  end

  # may be convenient when working with enormous objects and
  # pretty_print is too slow
  SIMPLE_PRINT = proc do |output, value|
    begin
      output.puts value.inspect
    rescue RescuableException
      output.puts "unknown"
    end
  end

  # useful when playing with truly enormous objects
  CLIPPED_PRINT = proc do |output, value|
    output.puts Debunker.view_clip(value, id: true)
  end

  # Will only show the first line of the backtrace
  DEFAULT_EXCEPTION_HANDLER = proc do |output, exception, _|
    if UserError === exception && SyntaxError === exception
      output.puts "SyntaxError: #{exception.message.sub(/.*syntax error, */m, '')}"
    else
      output.puts "#{exception.class}: #{exception.message}"
      output.puts "from #{exception.backtrace.first}"
    end
  end

  DEFAULT_PROMPT_NAME = 'debunker'

  # The default prompt; includes the target and nesting level
  DEFAULT_PROMPT = [
                    proc { |target_self, nest_level, debunker|
                      "[#{debunker.input_array.size}] #{debunker.config.prompt_name}(#{Debunker.view_clip(target_self)})#{":#{nest_level}" unless nest_level.zero?}> "
                    },

                    proc { |target_self, nest_level, debunker|
                      "[#{debunker.input_array.size}] #{debunker.config.prompt_name}(#{Debunker.view_clip(target_self)})#{":#{nest_level}" unless nest_level.zero?}* "
                    }
                   ]

  DEFAULT_PROMPT_SAFE_OBJECTS = [String, Numeric, Symbol, nil, true, false]

  # A simple prompt - doesn't display target or nesting level
  SIMPLE_PROMPT = [proc { ">> " }, proc { " | " }]

  NO_PROMPT = [proc { '' }, proc { '' }]

  SHELL_PROMPT = [
                  proc { |target_self, _, _debunker_| "#{_debunker_.config.prompt_name} #{Debunker.view_clip(target_self)}:#{Dir.pwd} $ " },
                  proc { |target_self, _, _debunker_| "#{_debunker_.config.prompt_name} #{Debunker.view_clip(target_self)}:#{Dir.pwd} * " }
                 ]

  # A prompt that includes the full object path as well as
  # input/output (_in_ and _out_) information. Good for navigation.
  NAV_PROMPT = [
                proc do |_, _, _debunker_|
                  tree = _debunker_.binding_stack.map { |b| Debunker.view_clip(b.eval("self")) }.join " / "
                  "[#{_debunker_.input_array.count}] (#{_debunker_.config.prompt_name}) #{tree}: #{_debunker_.binding_stack.size - 1}> "
                end,
                proc do |_, _, _debunker_|
                  tree = _debunker_.binding_stack.map { |b| Debunker.view_clip(b.eval("self")) }.join " / "
                  "[#{_debunker_.input_array.count}] (#{ _debunker_.config.prompt_name}) #{tree}: #{_debunker_.binding_stack.size - 1}* "
                end,
               ]

  # Deal with the ^D key being pressed. Different behaviour in different cases:
  #   1. In an expression behave like `!` command.
  #   2. At top-level session behave like `exit` command.
  #   3. In a nested session behave like `cd ..`.
  DEFAULT_CONTROL_D_HANDLER = proc do |eval_string, _debunker_|
    if !eval_string.empty?
      eval_string.replace('') # Clear input buffer.
    elsif _debunker_.binding_stack.one?
      _debunker_.binding_stack.clear
      throw(:breakout)
    else
      # Otherwise, saves current binding stack as old stack and pops last
      # binding out of binding stack (the old stack still has that binding).
      _debunker_.command_state["cd"] ||= Debunker::Config.from_hash({}) # FIXME
      _debunker_.command_state['cd'].old_stack = _debunker_.binding_stack.dup
      _debunker_.binding_stack.pop
    end
  end

  DEFAULT_SYSTEM = proc do |output, cmd, _|
    if !system(cmd)
      output.puts "Error: there was a problem executing system command: #{cmd}"
    end
  end

  # Store the current working directory. This allows show-source etc. to work if
  # your process has changed directory since boot. [Issue #675]
  INITIAL_PWD = Dir.pwd

  # This is to keep from breaking under Rails 3.2 for people who are doing that
  # IRB = Debunker thing.
  module ExtendCommandBundle; end
end

require 'method_source'
require 'shellwords'
require 'stringio'
require 'strscan'
require 'coderay'
require 'debunker/slop'
require 'rbconfig'
require 'tempfile'
require 'pathname'

require 'debunker/version'
require 'debunker/repl'
require 'debunker/rbx_path'
require 'debunker/code'
require 'debunker/history_array'
require 'debunker/helpers'
require 'debunker/code_object'
require 'debunker/method'
require 'debunker/wrapped_module'
require 'debunker/history'
require 'debunker/command'
require 'debunker/command_set'
require 'debunker/commands'
require 'debunker/plugins'
require 'debunker/core_extensions'
require 'debunker/debunker_class'
require 'debunker/debunker_instance'
require 'debunker/cli'
require 'debunker/color_printer'
require 'debunker/pager'
require 'debunker/terminal'
require 'debunker/editor'
require 'debunker/rubygem'
require "debunker/indent"
require "debunker/last_exception"
require "debunker/prompt"
require "debunker/inspector"
require 'debunker/object_path'
require 'debunker/output'
