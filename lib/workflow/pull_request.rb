require File.join(File.dirname(__FILE__), 'factory')

module Flow
  module Workflow
    class PullRequest
      attr_accessor :repo, :pull, :jira

      def initialize(repo, pull)
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
        ci(repo.name).pending?(self)
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

      def green?
        ci(repo.name).is_green?(self)
      end

      def statuses
        @__statuses__ ||= {}
        @__statuses__[repo.name] ||= {}
        @__statuses__[repo.name][sha] ||= client.statuses(repo.name, sha)
      end

      def ci(repo)
        Flow::Workflow::Factory.instanceFor(repo, :ci)
      end

      def client
        @__client__ ||= Flow::Workflow::Factory.instanceFor(@repo.name, :scm)
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

      def comment_not_green(extra_message)
        message = "Pull request is not OK :disappointed_relieved:"
        if comments.empty?
          comment! "**#{message}** \n #{extra_message}"
        elsif !comments.last.attrs[:body].include? message
          comment! "**#{message}** \n #{extra_message}"
        end
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

      def repo_name
        repo.name
      end
    end
  end
end
