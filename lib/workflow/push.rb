require File.join(File.dirname(__FILE__), 'models', 'comment')
require File.join(File.dirname(__FILE__), 'factory')
require File.join(File.dirname(__FILE__), 'models', 'pull_request')

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
          pull_request(request).move_away!
        elsif scm.request_status_error?(request)
          pull_request(request).rebuild!
        end
      end

      def new_pr(request)
        pr = pull_request(request)
        if pr != false
          pr.treat_dependent
        end
      end

      protected

      def pull_request_from_pull_request(request)
        scm.pull_request_object_from_pull_request request
      end

      def pull_request(request)
        scm.pull_request_from_request request
      end

      def scm
        @__scm__ ||= Flow::Workflow::Factory.instance(@repo_name, :source_control)
      end

    end
  end
end