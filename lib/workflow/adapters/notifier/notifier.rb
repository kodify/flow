require File.join(File.dirname(__FILE__), '..', 'adapter')

module Flow
  module Workflow
    class Notifier < Flow::Workflow::Adapter
      attr_accessor :room

      def initialize(config, options = {})
        super
        @thor   = options[:thor]
      end
    end
  end
end