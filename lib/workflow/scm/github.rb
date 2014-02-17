require 'octokit'

module Flow
  module Workflow
    class Github

      def initialize(config, options = {})
        @config = config
      end

      def add_comment(repo, number, body)
        client.add_comment repo, number, body
      end

      def statuses(repo, sha)
        client.statuses repo, sha
      end

      def merge_pull_request(repo, number, body)
        client.merge_pull_request repo, number, body
      end

      def delete_ref(repo, ref)
        client.delete_ref(repo, ref)
      end

      def create_issue(name, title, body, options)
        client.create_issue name, title, body, options
      end

      def pull_requests(name)
        client.pull_requests name
      end

      def issues(name)
        client.issues name
      end

      protected

      def client
        @__octokit_client__ ||= begin
          Octokit::Client.new(
              :login    => config['login'],
              :password => config['password']
          )
        end
      end
    end
  end
end