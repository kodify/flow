require 'rspec'
require 'rack/test'
require File.join(File.dirname(__FILE__), '..', 'lib', 'config')

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

def base_path
  @base_path ||= File.join(File.dirname(__FILE__), '..')
end

def mock_template(adapter, template, replacement = {})
  path = File.join(File.dirname(__FILE__), 'mock', 'responses', adapter, template)
  content = open "#{path}.json", &:read
  replacement.each do |key, value|
    content.gsub!(key, value)
  end
  content
end

def config
  Flow::Config.get
end

RSpec.configure do |c|
  c.backtrace_exclusion_patterns = []
  c.include Rack::Test::Methods
end

if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
  dir = File.join(base_path, 'build', 'coverage')
  SimpleCov.coverage_dir(dir)
  SimpleCov.start do
    add_filter '/spec/'
  end

end