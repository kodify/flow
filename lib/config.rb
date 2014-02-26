require 'singleton'
require 'yaml'

module Flow
  class Config
    include ::Singleton

    def self.get
      @__config__ ||= begin
        # return eval(ENV['FLOW_CONFIG']) if ENV.include? 'FLOW_CONFIG'
        path = '../config/parameters.yml'
        if ENV['RAILS_ENV'] == 'test'
          path = '../config/parameters.yml.tpl'
        end
        YAML::load_file(File.join(File.dirname(__FILE__), path))['parameters']
      end
    end
  end
end
