require File.join(File.dirname(__FILE__), '..', 'adapter')

module Flow
  module Workflow
    class SourceControl < Flow::Workflow::Adapter

      def add_comment(repo, number, body)
      end

      def statuses(repo, sha)
      end

      def merge_pull_request(repo, number, body)
      end

      def delete_ref(repo, ref)
      end

      def create_issue(name, title, body, options)
      end

      def pull_requests(name)
      end

      def issues(name)
      end

      def delete_branch(repo, branch)

      end

      def comment!(repo, number, body)

      end

      def pull_request(repo_name, pull_request_number)

      end

      def comment_from_request(request)

      end

      def request_status_success?(request)
        true
      end

    end
  end
end