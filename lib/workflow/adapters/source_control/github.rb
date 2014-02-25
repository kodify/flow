require 'octokit'
require File.join(File.dirname(__FILE__), 'source_control')
require File.join(File.dirname(__FILE__), '..', '..', 'pull_request')
require File.join(File.dirname(__FILE__), '..', '..', 'comment')
require File.join(File.dirname(__FILE__), '..', '..', 'repo')

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

      def comment!(repo, number, body)
        client.add_comment repo, number, body
      end

      def pull_request(repo_name, pull_request_number)
        repo = Repo.new repo_name
        pull = client.pull_request repo_name, pull_request_number
        Flow::Workflow::PullRequest.new(repo,
                                        id:         pull.id,
                                        sha:        pull.head.attrs[:sha],
                                        title:      pull.title,
                                        number:     pull.number,
                                        branch:     pull.head.label.split(':')[1],
                                        comments:   pull.rels[:comments].get.data,
        )
      end

      def comment_from_request(request)
        properties = {
            id:                   request['comment']['id'],
            url:                  request['comment']['url'],
            html_url:             request['comment']['html_url'],
            issue_url:            request['comment']['issue_url'],
            user_name:            request['comment']['user']['login'],
            created_at:           request['comment']['created_at'],
            updated_at:           request['comment']['updated_at'],
            body:                 request['comment']['body'],
            repo_name:            request['repository']['full_name'],
            pull_request_number:  request['issue']['number'] }

        Flow::Workflow::Comment.new properties
      end

      def request_status_success?(request)
        request['state'] == 'success'
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