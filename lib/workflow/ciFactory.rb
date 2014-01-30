require 'json'
require File.join(File.dirname(__FILE__), '../config')


module Flow
  module Workflow
    class CiFactory
      def self.instanceFor(repo)
        ciClass = Config.get['projects'][repo]['ci']
        return  Object.const_get("Flow::Workflow::#{ciClass}").new
      end
    end
  end
end