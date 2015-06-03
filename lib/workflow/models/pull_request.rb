require File.join(File.dirname(__FILE__), '..', 'factory')

module Flow
  module Workflow
    class PullRequest
      attr_accessor :repo, :pull, :id, :title, :number, :branch, :sha, :comments

      def initialize(repo, properties)
        @repo     = repo
        @id       = properties[:id]
        @sha      = properties[:sha]
        @title    = properties[:title]
        @number   = properties[:number]
        @branch   = properties[:branch]
        @comments = properties[:comments]
      end

      def status(standalone = nil)
        @__status__ ||= begin
          return :blocked                     if blocked?
          return :pending                     if pending?
          return :failed                      if !green?
          return :not_reviewed                if !reviewed?
          return :uat_ko                      if uat_ko?
          return :not_reviewed_on_all_repos   if !(!standalone.nil? or all_repos_on_status?(:not_uat))
          return :not_success_on_all_repos    if !(!standalone.nil? or all_repos_on_status?(:success))
          return :not_uat                     if !uat?
          :success
        end
      end

      def blocked?
        has_comment_with?(dictionary['blocked'])
      end

      def pending?
        ci.pending?(self)
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
        ci.is_green?(self)
      end

      def ignore?
        dictionary['ignore'].any? do |pattern|
          @title.include?(pattern)
        end
      end

      def rebuild!
        notifier.say_rebuild(self) if ci.rebuild! self
      end

      def ship_it!
        comment! dictionary['uat_ok'][0]
      end

      def boom_it!
        comment! dictionary['uat_ko'][0]
      end

      def block_it!(message)
        comment! "#{dictionary['blocked'][0]} - #{message}"
      end

      def move_away!
        case status
          when :success
            integrate!
          when :not_uat
            to_uat!
          else
            if issue_tracker_id
              notifier.cant_flow self
            end
        end
      end

      def comment!(body)
        scm.comment! repo.name, @number, body
      end

      def comment_not_green!(extra_message)
        message = "Pull request is not OK :disappointed_relieved:"
        if @comments.empty?
          comment! "**#{message}** \n #{extra_message}"
        elsif !@comments.last.attrs[:body].include? message
          comment! "**#{message}** \n #{extra_message}"
        end
      end

      def to_uat!
        if issue_tracker_id
          notifier.say_moved issue_tracker_id, 'ready_uat'
          issue_tracker.do_move :ready_uat, issue_tracker_id
        end
      end

      def to_in_progress!
        if issue_tracker_id
          notifier.say_moved issue_tracker_id, 'uat_nok'
          issue_tracker.do_move :uat_nok, issue_tracker_id
        end
      end

      def to_done!
        if issue_tracker_id
          notifier.say_moved issue_tracker_id, 'done'
          issue_tracker.do_move :done, issue_tracker_id
        end
      end

      def statuses
        @__statuses__ ||= {}
        @__statuses__[repo.name] ||= {}
        @__statuses__[repo.name][sha] ||= scm.statuses(repo.name, sha)
      end

      def all_repos_on_status?(status = :success)
        repo.related_repos.each do |related_repo|
          pr = related_repo.pull_request_by_name(issue_tracker_id)
          next if pr.nil?
          return false unless pr.status(true) == status(true)
        end
        true
      end

      def treat_dependent
        repo.dependent_repos.each do |dependent_repo|
          repository =  dependent_repo[0]
          submodule_path = dependent_repo[1]
          where = '/tmp/repos'
          repository.clone_into(where)
          repository.update_dependent(where,submodule_path, branch)
          repository.create_pull_request(where,submodule_path, branch, title)
        end
      end

      def merge
        message = "#{@branch} #UAT-OK - PR #{number} merged"
        scm.merge_pull_request(repo.name, @number, message)
      rescue
        false
      end

      def delete_branch
        scm.delete_branch repo.name, @branch unless @branch.include? 'master'
      end

      def issue_tracker_id
        issue_tracker.branch_to_id(branch) or branch
      end

      def save_comments_to_be_discussed
        @comments.each do |comment|
          name = issue_id comment
          repo.issue! "#{name}", "To Discuss : #{comment.body}", labels: 'to_discuss' if comment.body.include? ':exclamation:'
        end
      end

      def repo_name
        repo.name
      end

      def text_link
        "https://github.com/#{repo_name}/pull/#{@number} "
      end

      def html_link
        "<a href=\"https://github.com/#{repo_name}/pull/#{@number}\">https://github.com/#{repo_name}/pull/#{@number}</a>"
      end

      def log(log_message)
        notifier.log log_message
      end

      protected

      def integrate!
        return if status != :success
        if merge == false
          require_rebase
        else
          notifier.say_merged issue_tracker_id, branch
        end
      end

      def require_rebase
        if issue_tracker_id
          block_it! "Can't automerge this pull request"
          to_in_progress!
          notifier.say_merge_failed issue_tracker_id
        end
      end

      def issue_id(comment)
        "[#{@branch}:#{comment.id}]"
      end

      def has_comment_with?(patterns)
        patterns.any? do |pattern|
          @comments.any? { |s| s.body.include?(pattern) }
        end
      end

      def dictionary
        @__dictionary__ ||= Flow::Config.get['dictionary']
      end

      def ci
        @__ci__ ||= Flow::Workflow::Factory.instance(repo.name, :continuous_integration)
      end

      def issue_tracker
        @__it__ ||= Flow::Workflow::Factory.instance(repo.name, :issue_tracker)
      end

    def notifier
      @__notifier__ ||= Flow::Workflow::Factory.instance(@repo.name, :notifier, thor: @thor)
    end

    def scm
        @__client__ ||= Flow::Workflow::Factory.instance(@repo.name, :source_control)
      end
    end
  end
end
