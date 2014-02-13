require 'rspec'
require 'rack/test'

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

def base_path
  @base_path ||= File.join(File.dirname(__FILE__), '..')
end

RSpec.configure do |c|
  c.backtrace_exclusion_patterns = []
  c.include Rack::Test::Methods
end
