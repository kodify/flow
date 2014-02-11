require File.join(File.dirname(__FILE__), 'jenkins')
require File.join(File.dirname(__FILE__), 'scrutinizer')
require File.join(File.dirname(__FILE__), 'ci_factory')

module Flow
  module Workflow
    class PullRequest
      attr_accessor :client, :repo, :pull, :jira

      def initialize(client, repo, pull)
        @client = client
        @repo   = repo
        @pull   = pull
      end

      def has_comment_with?(patterns)
        patterns.any? do |pattern|
          comments.any? { |s| s.body.include?(pattern) }
        end
      end
      
      def blocked?
        has_comment_with?(dictionary['blocked'])
      end

      def pending?
        client.statuses(repo.name, sha).each do |state|
          return true if state.attrs[:state] == 'pending'
        end
        false
      end

      def reviewed?
        has_comment_with?(dictionary['reviewed'])
      end

      def uat?
        has_comment_with?(dictionary['uat_ok'])
      end

      def uat_ko?
        has_comment_with?(dictionary['uat_ko'])
      end

      def last_status
        client.statuses(repo.name, sha).any? do |state|
          return state unless state.attrs[:description].include? 'Scrutinizer'
        end
      end

      def green?
        ci( repo.name ).is_green?( repo.name, original_branch, target_url ) and last_status == 'success'
      end

      def target_url
        target = client.statuses( repo.name, sha ).last.rels[:target]
        if target.nil?
          ''
        else
          target.href
        end
      end

      def ci(repo)
        Flow::Workflow::CiFactory.instanceFor repo
      end

      def all_repos_on_status?(repos = [], status = :success)
        repos.each do |repo|
          pr = repo.pull_request_by_name(jira_id)
          next if pr.nil?
          return false unless pr.status == status
        end
        true
      end

      def status
        @__status__ ||= begin
          return :blocked       if blocked?
          return :pending       if pending?
          return :failed        if !green?
          return :not_reviewed  if !reviewed?
          return :uat_ko        if uat_ko?
          return :not_uat       if !uat?
          :success
        end
      end

      def comments
        @__comments__ ||= []
        @__comments__[pull.id] ||= pull.rels[:comments].get.data
      end

      def merge
        message = "#{original_branch} #UAT-OK - PR #{number} merged"
        begin
          response = client.merge_pull_request(repo.name, pull.number, message)
          response['merged']
        rescue
          false
        end
      end

      def delete_original_branch
        client.delete_ref(repo.name, "heads/#{original_branch}") unless original_branch.include? 'master'
      end

      def original_branch
        @__original_branch__ ||= pull.head[:label].split(':')[1]
      end

      def number
        pull.number
      end

      def jira_id
        original_branch.match('([a-zA-Z]{2,3})-([0-9]{1,})')
      end

      def save_comments_to_be_discussed
        comments.each do |comment|
          name = issue_id comment
          repo.issue! "#{name}", "To Discuss : #{comment.body}", labels: 'to_discuss' if comment.body.include? ':exclamation:'
        end
      end

      def issue_id(comment)
        "[#{original_branch}:#{comment.id}]"
      end

      def ship_it!
        comment! dictionary['uat_ok'][0]
      end

      def boom_it!
        comment! dictionary['uat_ko'][0]
      end

      def comment!(body)
        client.add_comment(repo.name, pull.number, body)
      end

      def commentNotGreen
        message = 'Pull request is not OK :disappointed_relieved:'
        comment! message unless comments.last.attrs[:body] == message
      end

      def to_uat(jira)
        if jira_id
          jira.do_move :ready_uat, jira_id
        end
      end

      def to_in_progress(jira)
        if jira_id
          jira.do_move :uat_nok, jira_id
        end
      end

      def to_done(jira)
        if jira_id
          jira.do_move :done, jira_id
        end
      end

      def dictionary
        @__dictionary__ ||= Flow::Config.get['dictionary']
      end

      def ignore
        pull.title.include? dictionary['ignore']
      end

      def sha
        pull.head.attrs[:sha]
      end
    end
  end
end
