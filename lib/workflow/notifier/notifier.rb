module Flow
  module Workflow
    class Notifier
      attr_accessor :room

      def initialize(config, options = {})
        @config = config
        @thor   = options[:thor]
      end
    end
  end
end