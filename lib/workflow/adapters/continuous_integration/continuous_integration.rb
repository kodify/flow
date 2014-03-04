require File.join(File.dirname(__FILE__), '..', 'adapter')

module Flow
  module Workflow
    class ContinuousIntegration < Flow::Workflow::Adapter

      def is_green?(pull_request)
        true
      end

      def pending?(pr)
        false
      end

      def rebuild!(pr)

      end

    end
  end
end