# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "testr/version"

Gem::Specification.new do |s|
  s.name        = "testr"
  s.version     = TestR::VERSION
  s.authors,
  s.email       = File.read('LICENSE').scan(/Copyright \d+ (.+) <(.+?)>/).transpose
  s.homepage    = "http://github.com/sunaku/testr"
  s.summary     = "Continuous testing tool for Ruby"
  s.description = nil

  s.files         = `git ls-files`.split("\n") + Dir['man/**/*']
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  s.add_runtime_dependency "json", ">= 1.6.1"
  s.add_runtime_dependency "guard", ">= 0.8.4"
  s.add_runtime_dependency "diff-lcs", ">= 1.1.2"

  # add binman and all of its development dependencies
  binman_gem = ['binman', '~> 1']
  s.add_runtime_dependency(*binman_gem)
  binman_vers = Gem::Dependency.new(*binman_gem)
  binman_spec = Gem::SpecFetcher.fetcher.fetch(binman_vers).flatten.first
  binman_spec.development_dependencies.unshift(binman_vers).each do |dep|
    s.add_development_dependency dep.name, dep.requirements_list
  end
end
