require 'rubygems'
require 'rest_client'

require File.join(File.dirname(__FILE__), 'issue_tracker')

module Flow
  module Workflow
    class Jira < Flow::Workflow::IssueTracker

      def do_move(status_id, issue)
        return :fail unless @status.keys.include?(status_id)
        return :fail unless issue.is_a? String
        json = data_for_move status_id
        url  = issue_url_with_status(issue, status_id)
        curl(@user, @pass, json, url)
      end

      def issues_by_status(status_name)
        url     = "#{@url}/rest/api/latest/search?jql='status'='#{status_name}'"
        issues  = get_collection(url)
        return [] if issues.nil? || !issues.include?('issues')
        issues['issues']
      end

      def branch_to_id(branch)
        branch.match('([a-zA-Z]{2,3})-([0-9]{1,})').to_s
      end

      protected

      def curl(user, pass, json, url)
        `curl -D- -u #{user}:#{pass} -X POST --data '#{json}' -H "Content-Type: application/json" #{url}`
        # FIXME process output to search
        :success # or :fail on fail
      end

      def get_collection(url)
        response = request url
        response.body.force_encoding('UTF-8')
        JSON.parse(response.to_str)
      end

      def request(url)
        @__client__ ||= begin
          #FIXME: Move this to a OAuth authentication
          RestClient::Request.new(
              method:   :get,
              url:      url,
              user:     @user,
              password: @pass,
              headers:  { :accept => :json,
                          :content_type => :json }
          ).execute
        end
      end

      def data_for_move(status_id)
        "{\"transition\":{\"id\" : \"#{@status[status_id]}\"}}"
      end

      def issue_url_with_status(issue, status_id)
        "#{@url}/rest/api/latest/issue/#{issue}/transitions\?expand\=transitions.fields\&transitionId\=#{@status[status_id]}"
      end

    end
  end
end