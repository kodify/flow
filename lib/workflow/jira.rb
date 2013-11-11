module Flow
  module Workflow
    class Jira
      def do_move(status_id, issue)
        json = data_for_move status_id
        output = `curl -D- -u #{user}:#{pass} -X POST --data '#{json}' -H "Content-Type: application/json" #{issue_url(issue, status_id)}`
        # puts output
      end

      protected

      def status
        { ready_uat:  Flow::Config.get['jira']['transitions']['ready_uat'],
          uat_nok:    Flow::Config.get['jira']['transitions']['uat_nok'],
          done:       Flow::Config.get['jira']['transitions']['done'] }
      end

      def user
        Flow::Config.get['jira']['user']
      end

      def pass
        Flow::Config.get['jira']['pass']
      end

      def issue_url(issue, status_id)
        "#{config['jira']['url']}/rest/api/latest/issue/#{issue}/transitions\?expand\=transitions.fields\&transitionId\=#{status[status_id]}"
      end

      def data_for_move(status_id)
        "{\"transition\":{\"id\" : \"#{status[status_id]}\"}}"
      end

      def config
        @__config__ ||= Flow::Config.get
      end
    end
  end
end