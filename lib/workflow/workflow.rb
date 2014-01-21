require 'octokit'
require 'digest/md5'

require File.join(File.dirname(__FILE__), 'notifier')
require File.join(File.dirname(__FILE__), 'pull_request')
require File.join(File.dirname(__FILE__), 'repo')
require File.join(File.dirname(__FILE__), 'jira')
require File.join(File.dirname(__FILE__), 'jenkins')

require File.join(File.dirname(__FILE__), '..', 'config')

module Flow
  module Workflow
    class Workflow
      attr_accessor :__notifier__

      def initialize(thor_instance = nil)
        @thor = thor_instance
      end

      def flow(repo_name)
        @pr_to_be_reviewed = []
        @repo_name = repo_name

        open_pull_requests.each do |pr|
          if !pr.ignore
            notifier.say_processing pr
            process_pull_request pr
          end
        end

        ask_for_reviews
      end

      def octokit_client
        @__octokit_client__ ||= begin
          Octokit::Client.new(
              :login    => config['github']['login'],
              :password => config['github']['password']
          )
        end
      end

      protected

      def process_pull_request(pr)
        if pr.status == :success and pr.all_repos_on_status?(valid_repos)
          pr.save_comments_to_be_discussed
          integrate_pull_request pr
        elsif pr.status == :uat_ko
          pr.to_in_progress jira
        elsif pr.status == :not_uat and pr.all_repos_on_status?(valid_repos, :not_uat)
          pr.to_uat jira
        elsif pr.status == :not_reviewed
          @pr_to_be_reviewed << pr
        else
          notifier.say_cant_merge pr
        end
      end

      def integrate_pull_request(pr)
        if pr.merge == false
          notifier.say_cant_merge pr
          return
        end

        pr.delete_original_branch
        pr.to_done jira
        # FIXME : This is always building fux
        big_build 'fux'
        notifier.say_merged pr
        notifier.say_big_build_queued
      end

      def big_build(project)
        jenkins = Flow::Workflow::Jenkins.new
        jenkins.big_build project
      end

      def ask_for_reviews
        return if !ask_for_reviews?

        qty     = @pr_to_be_reviewed.length
        message = html_message = "There are #{qty} PR ready to be reviewed in #{@repo_name} repo:"

        @pr_to_be_reviewed.each do |pr|
            message += "\n  #{pr.original_branch} - https://github.com/#{@repo_name}/pull/#{pr.number} "
            html_message += "<br> - #{pr.original_branch} - <a href=\"https://github.com/#{repo_name}/pull/#{pr.number}\">https://github.com/#{@repo_name}/pull/#{pr.number}</a>"
        end

        notifier.say html_message, :notify => true, :message_format => 'html'
      end

      def ask_for_reviews?
        return unless @pr_to_be_reviewed.length >= config['flow']['pending_pr_to_notify']
        return unless ask_for_reviews_interval > config['flow']['pending_pr_interval_in_sec']

        File.open(elapsed_time_file_name, 'w') {}
        true
      end

      def ask_for_reviews_interval
        now = Time.now.utc
        begin
          last_notification = File.mtime(elapsed_time_file_name)
        rescue
          last_notification = Time.now.utc - config['flow']['pending_pr_interval_in_sec'] - 1
        end

        return now - last_notification
      end

      def open_pull_requests
        Repo.new(octokit_client, @repo_name).pull_requests
      end

      def elapsed_time_file_name
        @__file_name__ = '/tmp/flow_pending_pr_' + Digest::MD5.hexdigest(@repo_name)
      end

      def notifier
        @__notifier__ ||= Flow::Workflow::Notifier.new @thor
      end

      def repo
        @__repo__ ||= Repo.new(octokit_client, repo)
      end

      def valid_repos
        @__valid_repos__ ||= begin
          repos = []
          unless config['valid_repos'].nil?
            config['valid_repos'].each do |repo|
              repos << Repo.new(octokit_client, repo)
            end
          end
          repos
        end
      end

      def jira
        @__jira__ ||= Jira.new
      end

      def config
        @__config__ ||= Flow::Config.get
      end
    end
  end
end