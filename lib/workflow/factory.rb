require 'json'
require File.join(File.dirname(__FILE__), '../config')

require File.join(File.dirname(__FILE__), 'adapters', 'adapter_container')

module Flow
  module Workflow
    class Factory
      def self.instance(repo, type, options = {})
        type = type.to_s
        @__ci_instances__ ||= {}
        @__ci_instances__[type] ||= {}
        @__ci_instances__[type][repo] ||= type_adapter_container(repo, type, options)
      end

      protected

      def self.type_adapter_container(repo, type, options)
        container = AdapterContainer.new
        raise "Non configured repo #{repo}" unless Flow::Config.get['projects'].include? repo
        raise "Non configured #{type} for #{repo} repo" unless Flow::Config.get['projects'][repo].include? type
        Flow::Config.get['projects'][repo][type].each do |adapter_name, custom_config|
          config = adapter_config(adapter_name, custom_config)
          container.add_adapter adapter(config, options)
        end
        container
      end

      def self.adapter(config, options)
        Flow.const_get('Workflow').const_get(config['class_name']).new(config, options)
      end

      def self.adapter_config(adapter_name, custom_config)
        custom_config = {} if custom_config.nil?
        Flow::Config.get['adapters'][adapter_name].merge custom_config
      end
    end
  end
end