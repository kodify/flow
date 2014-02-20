require 'octokit'
require File.join(File.dirname(__FILE__), 'source_control')
require File.join(File.dirname(__FILE__), '..', '..', 'pull_request')

module Flow
  module Workflow
    class Github < Flow::Workflow::SourceControl

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

      def pull_requests(repo)
        client.pull_requests(repo.name).map do |pull|
          PullRequest.new(repo,
                          id:         pull.id,
                          sha:        pull.head.attrs[:sha],
                          title:      pull.title,
                          number:     pull.number,
                          branch:     pull.head[:label].split(':')[1],
                          comments:   pull.rels[:comments].get.data,
          )
        end
      end

      def issues(name)
        client.issues name
      end

      def delete_branch(repo, branch)
        # TODO Add non-deleteable branches config
        client.delete_ref(repo, "heads/#{branch}")
      end

      protected

      def client
        @__octokit_client__ ||= begin
          Octokit::Client.new(
              :login    => @config['login'],
              :password => @config['password']
          )
        end
      end
    end
  end
end