module Flow
  module Workflow
    class Repo
      attr_accessor :client, :name

      def initialize(repo_name)
        @name   = repo_name
      end

      def pull_requests
        @__pull_requests__ ||= pulls
      end

      def pull_request_by_name(name)
        pulls.find { |pull| pull.jira_id.to_s == name }
      end
      
      def issue_exists(issue_name)
        issues.any? { |issue| issue.title.include? issue_name }
      end

      def issue!(title, body = '', options = {})
        return if issue_exists(title)
        client.create_issue(name, title, body, options)
      end

      protected

      def pulls
        client.pull_requests(name).map do |pull|
          PullRequest.new(self, pull)
        end
      end

      def issues
        client.issues(name)
      end

      def client
        @__client__ ||= Flow::Workflow::Factory.instanceFor(@repo, :scm)
      end
    end
  end
end
