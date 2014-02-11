require 'json'
require File.join(File.dirname(__FILE__), '../config')


module Flow
  module Workflow
    class CiFactory
      def self.instanceFor(repo)
        @__ci_instances__ ||= {}
        @__ci_instances__[repo] ||= begin
          ci_class = Config.get['projects'][repo]['ci']
          Flow.const_get('Workflow').const_get(ci_class).new
        end
      end
    end
  end
end