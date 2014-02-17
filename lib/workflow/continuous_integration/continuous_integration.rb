module Flow
  module Workflow
    module ContinuousIntegration
      attr_accessor :config

      def initialize(config, options = {})
        @config = config
      end

      def is_green?(repo, branch, target_url)
        raise 'Method #is_green? not implemented'
      end
    end
  end
end