require 'singleton'
require 'yaml'

module Flow
  class Config
    include ::Singleton

    def self.get
      @__config__ ||= begin
        return ENV['flow_config'] if ENV.include? 'flow_config'
        YAML::load_file(File.join(File.dirname(__FILE__), '../config/parameters.yml'))['parameters']
      end
    end
  end
end
