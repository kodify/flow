require File.join(File.dirname(__FILE__), 'factory')

module Flow
  module Workflow
    class Issue
      attr_accessor :issue_tracker, :key, :summary, :assignee

      def initialize(issue_tracker, properties)
        @issue_tracker  = issue_tracker
        @key            = properties[:key]
        @summary        = properties[:summary]
        @assignee       = properties[:assignee]
      end

      def url
        "#{@issue_tracker.url}#{@key}/browse/"
      end

      def html_link
        "<a href='#{url}'>#{@key}</a> - #{@summary}"
      end
    end
  end
end