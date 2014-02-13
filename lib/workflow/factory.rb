require 'json'
require File.join(File.dirname(__FILE__), '../config')
require File.join(File.dirname(__FILE__), 'continuous_integration', 'jenkins')
require File.join(File.dirname(__FILE__), 'continuous_integration', 'scrutinizer')
require File.join(File.dirname(__FILE__), 'issue_tracker', 'jira')

module Flow
  module Workflow
    class Factory
      def self.instanceFor(repo, type)
        @__ci_instances__ ||= {}
        @__ci_instances__[type.to_s] ||= {}
        @__ci_instances__[type.to_s][repo] ||= begin
          config = Flow::Config.get['projects'][repo][type.to_s]

          Flow.const_get('Workflow').const_get(config['class_name']).new(config)
        end
      end
    end
  end
end