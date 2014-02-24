require File.join(File.dirname(__FILE__), '..', 'adapter')

module Flow
  module Workflow
    class ContinuousIntegration < Flow::Workflow::Adapter

      def is_green?(repo, branch, target_url)
        raise 'Method #is_green? not implemented'
      end

      def pending?(pr)
        false
      end

    end
  end
end