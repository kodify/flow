require File.join(File.dirname(__FILE__), 'repo')
require File.join(File.dirname(__FILE__), 'factory')
require File.join(File.dirname(__FILE__), '..', 'config')

module Flow
  module Workflow
    class Tracker
      ##
      # Wil review bottlenecks on unassigned uat stories
      #
      def uat_bottlenecks
        issues = issue_tracker.unassigned_issues_by_status 'UAT'

        if issues.length >= issue_tracker.min_unassigned_uats
          notifier.say_uat_bottlenecks(issues.length, issues_list(issues))
        end
      end

      ##
      # Will review bottlenecks on code review
      #
      def review_bottlenecks
        pull_requests = open_pull_requests
        notify_review(pull_requests) if pull_requests.length >= config['flow']['pending_pr_to_notify']
      end

      protected

      def issues_list(issues)
        message = ''
        issues.each do |issue|
          message += "<br /> - #{issue.html_link}"
        end
        message
      end

      def notify_review(pull_requests)
        message = html_message = "There are #{pull_requests.length} PR ready to be reviewed:"

        pull_requests.each do |pull_request|
          message += "\n  #{pull_request.branch} - #{pull_request.text_link} "
          html_message += "<br> - #{pull_request.branch} - #{pull_request.html_link}"
        end

        notifier.say html_message, :notify => true, :message_format => 'html'
      end

      def open_pull_requests
        pull_requests = []
        repos.each do |repo_name|
          Repo.new(repo_name).pull_requests.each do |pull_request|
            pull_requests << pull_request if pull_request.status == :not_reviewed
          end
        end
        pull_requests
      end

      def repos
        config['projects'].keys
      end

      def config
        @__config__ ||= Flow::Config.get
      end

      def issue_tracker(repo = config['projects'].keys.first)
        @__it__ ||= Flow::Workflow::Factory.instance(repo, :issue_tracker)
      end

      def notifier(repo = config['projects'].keys.first)
        @__notifier__ ||= Flow::Workflow::Factory.instance(repo, :notifier, thor: self)
      end

    end
  end
end