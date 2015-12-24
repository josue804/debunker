# -*- encoding: utf-8 -*-
require File.expand_path('../lib/debunker/version', __FILE__)

Gem::Specification.new do |s|
  s.name    = "debunker"
  s.version = Debunker::VERSION

  s.required_ruby_version = '>= 1.9.3'

  s.authors = ["John Mair (banisterfiend)", "Conrad Irwin", "Ryan Fitzgerald"]
  s.email = ["jrmair@gmail.com", "conrad.irwin@gmail.com", "rwfitzge@gmail.com"]
  s.summary = "An IRB alternative and runtime developer console"
  s.description = s.summary
  s.homepage = "http://debunkerrepl.org"
  s.licenses = ['MIT']

  s.executables   = ["debunker"]
  s.require_paths = ["lib"]
  s.files         = `git ls-files bin lib *.md LICENSE`.split("\n")

  s.add_dependency 'coderay',       '~> 1.1.0'
  s.add_dependency 'method_source', '~> 0.8.1'
  s.add_development_dependency 'bundler', '~> 1.0'
end
