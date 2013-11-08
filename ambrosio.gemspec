# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'bundler/version'

Gem::Specification.new do |s|
  s.name        = "flow"
  s.version     = '0.0.5'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Adrià Cidre"]
  s.email       = ["adria@kodify.io"]
  s.homepage    = "http://github.com/kodify/flow"
  s.summary     = "Your help assistant"
  s.description = "Supu"

  s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE.txt README.md)
  s.executables  = ['kod']
  s.require_path = 'lib'

  s.executables << 'kod'

  s.add_runtime_dependency 'thor',    '~> 0.18'
end