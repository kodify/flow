require File.join(File.dirname(__FILE__), 'continuous_integration')

module Flow
  module Workflow
    class DummyCi < Flow::Workflow::ContinuousIntegration

    end
  end
end