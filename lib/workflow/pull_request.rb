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
        patterns.each do |pattern|
          return true if comments.any? { |s| s.body.include?(pattern) }
        end
        false
      end

      def blocked?
        has_comment_with?(dictionary['blocked'])
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
        client.statuses(repo.name, pull.head.attrs[:sha]).each do |state|
          return true if state.attrs[:state] == 'success'
        end
        false
      end

      def status
        @__status__ ||= begin
          return :blocked       if blocked?
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
          issue! 'To Discuss', comment.body if comment.body.include? ':exclamation:'
        end
      end

      def ship_it!
        comment! dictionary['uat_ok'][0]
      end

      def boom_it!
        comment! dictionary['uat_ko'][0]
      end

      def issue!(title, body = '')
        client.create_issue(repo.name, title, body, :labels => 'to_discuss')
      end

      def comment!(body)
        client.add_comment(repo.name, pull.number, body)
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

    end
  end
end