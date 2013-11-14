require 'rspec'
require 'rack/test'

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

@@base_path = File.join(File.dirname(__FILE__), '..')

RSpec.configure do |c|
  c.backtrace_exclusion_patterns = []
  c.include Rack::Test::Methods
end
