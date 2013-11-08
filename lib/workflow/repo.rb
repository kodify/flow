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

      protected

      def pulls
        pulls = []
        client.pull_requests(name).each do |pull|
          pulls << PullRequest.new(client, self, pull)
        end
        pulls
      end

    end
  end
end