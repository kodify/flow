module Flow
  module Workflow
    class Repo
      attr_accessor :client, :name

      def initialize(client, repo_name)
        @client = client
        @name   = repo_name
      end

      def pull_requests
        @__pull_requests__ ||= pulls
      end

      def pull_request_by_name(name)
        pulls.each do |pr|
          return pr if (pr.jira_id.to_s == name)
        end
        nil
      end

      def issue_exists(issue_name)
        issues.each do |issue|
          return true if issue.title.include? issue_name
        end
        false
      end

      def issue!(title, body = '', options = {})
        unless issue_exists(title)
          client.create_issue(name, title, body, options)
        end
      end

      protected

      def pulls
        pulls = []
        client.pull_requests(name).each do |pull|
          pulls << PullRequest.new(client, self, pull)
        end
        pulls
      end

      def issues
        issues = []
        client.issues(name).each do |issue|
          issues << issue
        end
        issues
      end

    end
  end
end