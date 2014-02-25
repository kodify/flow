require File.join(File.dirname(__FILE__), 'source_control')

module Flow
  module Workflow
    class DummyScm < Flow::Workflow::SourceControl

    end
  end
end