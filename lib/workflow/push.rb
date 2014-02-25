require File.join(File.dirname(__FILE__), 'comment')
require File.join(File.dirname(__FILE__), 'factory')
require File.join(File.dirname(__FILE__), 'pull_request')

module Flow
  module Workflow
    class Push

      def initialize(repo_name)
        @repo_name = repo_name
      end

      def new_comment(request)
        comment = scm.comment_from_request request
        return unless comment.modifies_workflow?
        return comment.pull_request.to_in_progress! if comment.uat_ko?

        comment.pull_request.move_away!
      end

      def status_update(request)
        if scm.request_status_success?(request)
          pull_request.move_away!
        end
      end

      protected

      def pull_request(request)
        scm.pull_request_from_request request
      end

      def scm
        @__scm__ ||= Flow::Workflow::Factory.instance(@repo_name, :source_control)
      end

      def ci
        @__ci__ ||= Flow::Workflow::Factory.instance(@repo_name, :continuous_integration)
      end

    end
  end
end