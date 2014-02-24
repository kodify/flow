require File.join(File.dirname(__FILE__), 'continuous_integration', 'jenkins')
require File.join(File.dirname(__FILE__), 'continuous_integration', 'scrutinizer')
require File.join(File.dirname(__FILE__), 'continuous_integration', 'travis')
require File.join(File.dirname(__FILE__), 'issue_tracker', 'jira')
require File.join(File.dirname(__FILE__), 'notifier', 'hipchat')
require File.join(File.dirname(__FILE__), 'source_control', 'github')

module Flow
  module Workflow
    class AdapterContainer
      attr_accessor :adapters

      def initialize(adapters = [])
        @adapters = adapters
      end

      def add_adapter(adapter)
        @adapters << adapter
      end

      def method_missing(method_id, *arguments)
        return adapters.first.send(method_id.to_sym, *arguments) if adapters.length == 1
        adapters.all? do |adapter|
          adapter.send(method_id.to_sym, *arguments)
        end
      end
    end
  end
end