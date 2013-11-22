require 'singleton'
require 'yaml'

module Flow
  class Config
    include ::Singleton

    def self.get
      @__config__ ||= begin
        return ENV['FLOW_CONFIG'] if ENV.include? 'FLOW_CONFIG'
        YAML::load_file(File.join(File.dirname(__FILE__), '../config/parameters.yml'))['parameters']
      end
    end
  end
end
