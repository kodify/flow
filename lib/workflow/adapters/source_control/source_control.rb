require File.join(File.dirname(__FILE__), '..', 'adapter')

module Flow
  module Workflow
    class SourceControl < Flow::Workflow::Adapter

      def add_comment(repo, number, body)
        raise 'Method #add_comment not implemented'
      end

      def statuses(repo, sha)
        raise 'Method #statuses not implemented'
      end

      def merge_pull_request(repo, number, body)
        raise 'Method #merge_pull_request not implemented'
      end

      def delete_ref(repo, ref)
        raise 'Method #delete_ref not implemented'
      end

      def create_issue(name, title, body, options)
        raise 'Method #create_issue not implemented'
      end

      def pull_requests(name)
        raise 'Method #pull_requests not implemented'
      end

      def issues(name)
        raise 'Method #issues not implemented'
      end

    end
  end
end