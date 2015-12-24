class Debunker::Command::GemReadme < Debunker::ClassCommand
  match 'gem-readme'
#'Show the readme bundled with a rubygem'
  group 'Gems'
  command_options argument_required: true
  banner <<-BANNER
    gem-readme gem
    Show the readme bundled with a rubygem
  BANNER

  def process(name)
    spec = Gem::Specification.find_by_name(name)
    glob = File.join(spec.full_gem_path, 'README*')
    readme = Dir[glob][0]
    if File.exist?(readme.to_s)
      _debunker_.pager.page File.read(readme)
    else
      raise Debunker::CommandError, "Gem '#{name}' doesn't appear to have a README"
    end
  rescue Gem::LoadError
    raise Debunker::CommandError, "Gem '#{name}' wasn't found. Are you sure it is installed?"
  end

  Debunker::Commands.add_command(self)
end
