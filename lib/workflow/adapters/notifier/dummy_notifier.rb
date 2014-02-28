require File.join(File.dirname(__FILE__), 'notifier')

module Flow
  module Workflow
    class DummyNotifier < Flow::Workflow::Notifier

    end
  end
end