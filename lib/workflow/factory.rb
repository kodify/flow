require 'json'
require File.join(File.dirname(__FILE__), '../config')
require File.join(File.dirname(__FILE__), 'continuous_integration', 'jenkins')
require File.join(File.dirname(__FILE__), 'continuous_integration', 'scrutinizer')
require File.join(File.dirname(__FILE__), 'issue_tracker', 'jira')
require File.join(File.dirname(__FILE__), 'notifier', 'hipchat')
require File.join(File.dirname(__FILE__), 'source_control', 'github')

module Flow
  module Workflow
    class Factory
      def self.instance(repo, type, options = {})
        @__ci_instances__ ||= {}
        @__ci_instances__[type.to_s] ||= {}
        @__ci_instances__[type.to_s][repo] ||= begin
          config = adapter_config(repo, type)
          Flow.const_get('Workflow').const_get(config['class_name']).new(config, options)
        end
      end

      def self.adapter_config(repo, type)
        config = Flow::Config.get['projects'][repo][type.to_s]
        if config.include? 'adapter'
          adapter = config['adapter']
          config = Flow::Config.get['adapters'][adapter].merge config
        end
        config
      end
    end
  end
end