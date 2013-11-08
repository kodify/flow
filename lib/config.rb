require 'singleton'
require 'yaml'

module Flow
  class Config
    include ::Singleton

    def self.get
      @__config__ ||= begin
        YAML::load_file(File.join(File.dirname(__FILE__), '../config/parameters.yml'))['parameters']
      end
    end
  end
end
