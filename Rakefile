require 'rake/clean'
require 'rubygems/package_task'

$:.unshift 'lib'
require 'debunker/version'

CLOBBER.include('**/*~', '**/*#*', '**/*.log')
CLEAN.include('**/*#*', '**/*#*.*', '**/*_flymake*.*', '**/*_flymake', '**/*.rbc', '**/.#*.*')

desc "Set up and run tests"
task :default => [:test]

def run_specs paths
  format = ENV['VERBOSE'] ? '--format documentation ' : ''
  sh "rspec -w #{format}#{paths.join ' '}"
end

desc "Run tests"
task :test do
  paths =
    if explicit_list = ENV['run']
      explicit_list.split(',')
    else
      Dir['spec/**/*_spec.rb'].shuffle!
    end
  run_specs paths
end
task :spec => :test

task :recspec do
  all = Dir['spec/**/*_spec.rb'].sort_by{|path| File.mtime(path)}.reverse
  warn "Running all, sorting by mtime: #{all[0..2].join(' ')} ...etc."
  run_specs all
end

desc "Run debunker (you can pass arguments using _ in place of -)"
task :debunker do
  ARGV.shift if ARGV.first == "debunker"
  ARGV.map! do |arg|
    arg.sub(/^_*/) { |m| "-" * m.size }
  end
  load 'bin/debunker'
end

desc "Show debunker version."
task :version do
  puts "Debunker version: #{Debunker::VERSION}"
end

desc "Profile debunker's startup time"
task :profile do
  require 'profile'
  require 'debunker'
  Debunker.start(TOPLEVEL_BINDING, :input => StringIO.new('exit'))
end

def modify_base_gemspec
  eval(File.read('debunker.gemspec')).tap { |s| yield s }
end

namespace :ruby do
  spec = modify_base_gemspec do |s|
    s.platform = Gem::Platform::RUBY
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = false
    pkg.need_tar = false
  end
end

namespace :jruby do
  spec = modify_base_gemspec do |s|
    s.add_dependency('spoon', '~> 0.0')
    s.platform = 'java'
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = false
    pkg.need_tar = false
  end
end


['mswin32', 'mingw32'].each do |platform|
  namespace platform do
    spec = modify_base_gemspec do |s|
      s.add_dependency('win32console', '~> 1.3')
      s.platform = Gem::Platform.new ['universal', platform, nil]
    end

    Gem::PackageTask.new(spec) do |pkg|
      pkg.need_zip = false
      pkg.need_tar = false
    end
  end

  task gems: "#{platform}:gem"
end

desc "build all platform gems at once"
task :gems => [:clean, :rmgems, 'ruby:gem', 'jruby:gem']

desc "remove all platform gems"
task :rmgems => ['ruby:clobber_package']
task :rm_gems => :rmgems
task :rm_pkgs => :rmgems

desc "reinstall gem"
task :reinstall => :gems do
  sh "gem uninstall debunker" rescue nil
  sh "gem install #{File.dirname(__FILE__)}/pkg/debunker-#{Debunker::VERSION}.gem"
end

task :install => :reinstall

desc "build and push latest gems"
task :pushgems => :gems do
  chdir("#{File.dirname(__FILE__)}/pkg") do
    Dir["*.gem"].each do |gemfile|
      sh "gem push #{gemfile}"
    end
  end
end

namespace :docker do
  desc "build a docker container with multiple rubies"
  task :build do
    system "docker build -t debunker/debunker ."
  end

  desc "test debunker on multiple ruby versions"
  task :test => :build do
    system "docker run -i -t -v /tmp/debunkertmp:/tmp/debunkertmp debunker/debunker ./multi_test_inside_docker.sh"
  end
end
