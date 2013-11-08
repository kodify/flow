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

      ##
      # Kodify workflow automation
      #
      def flow(repo_name)
        pending_pr_arr = []

        all_prs(client, repo_name).each do |pr|

          notifier.say_processing pr
          if (pr.status == :success)
            pr.save_comments_to_be_discussed
            integrate_pull_request pr
          elsif (pr.status == :uat_ko)
            pr.to_in_progress jira
          elsif (pr.status == :not_uat)
            pr.to_uat jira
          elsif (pr.status == :not_reviewed)
            pending_pr_arr << pr
          else
            notifier.say_cant_merge pr
          end
        end

        if pending_pr_arr.length >= config['flow']['pending_pr_to_notify']
          notify_review repo_name, pending_pr_arr
        end
      end

      def all_prs(client, repo_name)
        Repo.new(client, repo_name).pull_requests
      end

      def client
        @__client__ ||= begin
          Octokit::Client.new(
              :login    => config['github']['login'],
              :password => config['github']['password']
          )
        end
      end

      protected

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

      def notify_review(repo_name, pending_pr_arr)

        file_name   = '/tmp/flow_pending_pr_' + Digest::MD5.hexdigest(repo_name)
        interval    =  get_last_notification_elapsed_time file_name
        qty         = pending_pr_arr.length

        if interval > config['flow']['pending_pr_interval_in_sec']
            File.open(file_name, 'w') {}

            message         = "There are #{qty} PR ready to be reviewed in #{repo_name} repo:"
            html_message    = "There are #{qty} PR ready to be reviewed in #{repo_name} repo:"
            pending_pr_arr.each do |pr|
                message += "\n  #{pr.original_branch} - https://github.com/#{repo_name}/pull/#{pr.number} "
                html_message += "<br> - #{pr.original_branch} - <a href=\"https://github.com/#{repo_name}/pull/#{pr.number}\">https://github.com/#{repo_name}/pull/#{pr.number}</a>"
            end

            notifier.say html_message, :notify => true, :message_format => 'html'
        end
      end

      def get_last_notification_elapsed_time(file_path)
        now = Time.now.utc
        begin
          last_notification = File.mtime(file_path)
        rescue
          last_notification = Time.now.utc - config['flow']['pending_pr_interval_in_sec'] - 1
        end

        return now - last_notification
      end

      def notifier
        @__notifier__ ||= Flow::Workflow::Notifier.new @thor
      end

      def repo
        @__repo__ ||= Repo.new(client, repo)
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