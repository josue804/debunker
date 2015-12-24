class Debunker
  class Command::Version < Debunker::ClassCommand
    match 'debunker-version'
    group 'Misc'
  #'Show Debunker version.'

    banner <<-'BANNER'
      Show Debunker version.
    BANNER

    def process
      output.puts "Debunker version: #{Debunker::VERSION} on Ruby #{RUBY_VERSION}."
    end
  end

  Debunker::Commands.add_command(Debunker::Command::Version)
end
