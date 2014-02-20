module Flow
  module Workflow
    class Adapter
      attr_accessor :config

      def initialize(config, options = {})
        @config = config
      end
    end
  end
end