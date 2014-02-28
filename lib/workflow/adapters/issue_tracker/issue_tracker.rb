require File.join(File.dirname(__FILE__), '..', 'adapter')

module Flow
  module Workflow
    class IssueTracker < Flow::Workflow::Adapter
      attr_accessor :min_unassigned_uats, :url

      def do_move(status_id, issue)
      end

      def issues_by_status(status_name)
      end

      def branch_to_id(branch)
      end

      def unassigned_issues_by_status(status)
      end
    end
  end
end