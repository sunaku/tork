# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'tork/version'

Gem::Specification.new do |s|
  s.name          = 'tork'
  s.version       = Tork::VERSION
  s.authors,
  s.email         = File.read('LICENSE').scan(/Copyright \d+ (.+) <(.+?)>/).transpose
  s.homepage      = 'http://github.com/sunaku/tork'
  s.summary       = 'test with fork'
  s.description   = 'Runs your tests as they change, in parallel.'

  s.files         = `git ls-files`.split("\n") + Dir['man/**/*']
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency 'binman', '~> 3'
  s.add_runtime_dependency 'json', '>= 1.6.1', '< 2'
  s.add_runtime_dependency 'guard', '~> 1'
  s.add_runtime_dependency 'diff-lcs', '>= 1.1.2', '< 2'
  s.add_development_dependency 'md2man', '~> 1'
  s.add_development_dependency 'rake', '>= 0.9.2.2', '< 1'
end
