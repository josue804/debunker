class Debunker::Config::Default
  include Debunker::Config::Behavior

  default = {
    input: proc {
      lazy_readline
    },
    output: proc {
      $stdout.tap { |out| out.sync = true }
    },
    commands: proc {
      Debunker::Commands
    },
    prompt_name: proc {
      Debunker::DEFAULT_PROMPT_NAME
    },
    prompt: proc {
      Debunker::DEFAULT_PROMPT
    },
    prompt_safe_objects: proc {
      Debunker::DEFAULT_PROMPT_SAFE_OBJECTS
    },
    print: proc {
      Debunker::DEFAULT_PRINT
    },
    quiet: proc {
      false
    },
    exception_handler: proc {
      Debunker::DEFAULT_EXCEPTION_HANDLER
    },
    exception_whitelist: proc {
      Debunker::DEFAULT_EXCEPTION_WHITELIST
    },
    hooks: proc {
      Debunker::DEFAULT_HOOKS
    },
    pager: proc {
      true
    },
    system: proc {
      Debunker::DEFAULT_SYSTEM
    },
    color: proc {
      Debunker::Helpers::BaseHelpers.use_ansi_codes?
    },
    default_window_size: proc {
      5
    },
    editor: proc {
      Debunker.default_editor_for_platform
    }, # TODO: Debunker::Platform.editor
    should_load_rc: proc {
      true
    },
    should_load_local_rc: proc {
      true
    },
    should_trap_interrupts: proc {
      Debunker::Helpers::BaseHelpers.jruby?
    }, # TODO: Debunker::Platform.jruby?
    disable_auto_reload: proc {
      false
    },
    command_prefix: proc {
      ""
    },
    auto_indent: proc {
      Debunker::Helpers::BaseHelpers.use_ansi_codes?
    },
    correct_indent: proc {
      true
    },
    collision_warning: proc {
      false
    },
    output_prefix: proc {
      "=> "
    },
    requires: proc {
      []
    },
    should_load_requires: proc {
      true
    },
    should_load_plugins: proc {
      true
    },
    windows_console_warning: proc {
      true
    },
    control_d_handler: proc {
      Debunker::DEFAULT_CONTROL_D_HANDLER
    },
    memory_size: proc {
      100
    },
    extra_sticky_locals: proc {
      {}
    },
    command_completions: proc {
      proc { commands.keys }
    },
    file_completions: proc {
      proc { Dir["."] }
    },
    ls: proc {
      Debunker::Config.from_hash(Debunker::Command::Ls::DEFAULT_OPTIONS)
    },
    completer: proc {
      require "debunker/input_completer"
      Debunker::InputCompleter
    },
    exec_string: proc {
      ""
    }
  }

  def initialize
    super(nil)
    configure_gist
    configure_history
  end

  default.each do |key, value|
    define_method(key) do
      if default[key].equal?(value)
        default[key] = instance_eval(&value)
      end
      default[key]
    end
  end

private
  # TODO:
  # all of this configure_* stuff is a relic of old code.
  # we should try move this code to being command-local.
  def configure_gist
    self["gist"] = Debunker::Config.from_hash(inspecter: proc(&:pretty_inspect))
  end

  def configure_history
    self["history"] = Debunker::Config.from_hash "should_save" => true,
      "should_load" => true
    history.file = File.expand_path("~/.debunker_history") rescue nil
    if history.file.nil?
      self.should_load_rc = false
      history.should_save = false
      history.should_load = false
    end
  end

  def lazy_readline
    require 'readline'
    Readline
  rescue LoadError
    warn "Sorry, you can't use Debunker without Readline or a compatible library."
    warn "Possible solutions:"
    warn " * Rebuild Ruby with Readline support using `--with-readline`"
    warn " * Use the rb-readline gem, which is a pure-Ruby port of Readline"
    warn " * Use the debunker-coolline gem, a pure-ruby alternative to Readline"
    raise
  end
end
