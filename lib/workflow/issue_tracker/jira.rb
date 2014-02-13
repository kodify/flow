require 'rubygems'
require 'rest_client'

module Flow
  module Workflow
    class Jira
      attr_accessor :config

      def initialize(config)
        @config = config
      end

      def do_move(status_id, issue)
        json = data_for_move status_id
        output = `curl -D- -u #{user}:#{pass} -X POST --data '#{json}' -H "Content-Type: application/json" #{issue_url(issue, status_id)}`
        # puts output
      end

      def issues_by_status(status_name)
        url   = "#{config['url']}/rest/api/latest/search?jql='status'='#{status_name}'"
        get_collection(url)['issues']
      end

      def get_collection(url)
        response = RestClient::Request.new(
            method:   :get,
            url:      url,
            user:     user,
            password: pass,
            headers:  { :accept => :json,
                        :content_type => :json }
        ).execute
        response.body.force_encoding('UTF-8')
        JSON.parse(response.to_str)
      end

      protected

      def status
        { ready_uat:  Flow::Config.get['jira']['transitions']['ready_uat'],
          uat_nok:    Flow::Config.get['jira']['transitions']['uat_nok'],
          done:       Flow::Config.get['jira']['transitions']['done'] }
      end

      def user
        config['user']
      end

      def pass
        config['pass']
      end

      def issue_url(issue, status_id)
        "#{config['url']}/rest/api/latest/issue/#{issue}/transitions\?expand\=transitions.fields\&transitionId\=#{status[status_id]}"
      end

      def data_for_move(status_id)
        "{\"transition\":{\"id\" : \"#{status[status_id]}\"}}"
      end
    end
  end
end