require 'octokit'
require File.join(File.dirname(__FILE__), 'source_control')
require File.join(File.dirname(__FILE__), '..', '..', 'models', 'pull_request')
require File.join(File.dirname(__FILE__), '..', '..', 'models', 'comment')
require File.join(File.dirname(__FILE__), '..', '..', 'models', 'repo')

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
          new_pull_request repo, pull
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
        new_pull_request(repo, pull)
      end

      def comment_from_request(request)
        Flow::Workflow::Comment.new({ id:                   request['comment']['id'],
                                      url:                  request['comment']['url'],
                                      html_url:             request['comment']['html_url'],
                                      user_name:            request['comment']['user']['login'],
                                      created_at:           request['comment']['created_at'],
                                      updated_at:           request['comment']['updated_at'],
                                      body:                 request['comment']['body'],
                                      repo_name:            request['repository']['full_name'],
                                      issue_url:            request['comment']['issue_url'],
                                      pull_request_number:  request['issue']['number'] })
      end

      def pull_request_from_request(request)
        repo      = Repo.new request['repository']['full_name']
        sha       = request['branches'].first['commit']['sha']
        pull_requests(repo).each do |pr|
          return pr if pr.sha == sha
        end
      end

      def request_status_success?(request)
        request['state'] == 'success'
      end

      def request_status_error?(request)
        request['state'] == 'error'
      end

      def request_status_failed?(request)
        request['state'] == 'failed'
      end

      def related_repos
        configured_related_repos.map do |repo_name|
          Flow::Workflow::Repo.new(repo_name)
        end
      end

      protected

      def configured_related_repos
        config['related_repos']
      end

      def client
        @__octokit_client__ ||= begin
          if @config.include? 'access_token'
            Octokit::Client.new(:access_token => @config['access_token'])
          else
            Octokit::Client.new(
                :login    => @config['login'],
                :password => @config['password']
            )
          end
        end
      end

      def new_pull_request(repo, pull)
        Flow::Workflow::PullRequest.new(repo,
                                        id:         pull.id,
                                        sha:        pull.head.attrs[:sha],
                                        title:      pull.title,
                                        number:     pull.number,
                                        branch:     pull.head.label.split(':')[1],
                                        comments:   pull.rels[:comments].get.data,
        )
      end

    end
  end
end