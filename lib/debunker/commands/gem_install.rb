class Debunker
  class Command::GemInstall < Debunker::ClassCommand
    match 'gem-install'
    group 'Gems'
  #'Install a gem and refresh the gem cache.'
    command_options :argument_required => true

    banner <<-'BANNER'
      Usage: gem-install GEM_NAME

      Installs the given gem, refreshes the gem cache, and requires the gem for you
      based on a best guess from the gem name.

      gem-install debunker-stack_explorer
    BANNER

    def setup
      require 'rubygems/dependency_installer' unless defined? Gem::DependencyInstaller
    end

    def process(gem)
      Rubygem.install(gem)
      output.puts "Gem `#{ text.green(gem) }` installed."
      require gem
    rescue LoadError
      require_path = gem.split('-').join('/')
      require require_path
    end
  end

  Debunker::Commands.add_command(Debunker::Command::GemInstall)
end
