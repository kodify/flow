require File.join(File.dirname(__FILE__), 'factory')

module Flow
  module Workflow
    class Comment
      attr_accessor :id, :url, :html_url, :issue_url, :user_name, :created_at, :updated_at, :body

      def initialize(properties)
        @id                   = properties[:id]
        @url                  = properties[:url]
        @html_url             = properties[:html_url]
        @issue_url            = properties[:issue_url]
        @user_name            = properties[:user_name]
        @created_at           = properties[:created_at]
        @updated_at           = properties[:updated_at]
        @body                 = properties[:body]
        @repo_name            = properties[:repo_name]
        @pull_request_number  = properties[:pull_request_number]
      end

      def pull_request
        @__pull_request__ ||= scm.pull_request @repo_name, @pull_request_number
      end

      def uat_ok?
        dictionary['uat_ok'].any? { |word| @body.include?(word) }
      end

      def uat_ko?
        dictionary['uat_ko'].any? { |word| @body.include?(word) }
      end

      def code_review_ok?
        dictionary['reviewed'].any? { |word| @body.include?(word) }
      end

      def code_review_ko?
        dictionary['blocked'].any? { |word| @body.include?(word) }
      end

      def modifies_workflow?
        uat_ok? || code_review_ok? || pull_request.ignore?
      end

      protected

      def dictionary
        @__dictionary__ ||= Flow::Config.get['dictionary']
      end

      def scm
        @__scm__ ||= Flow::Workflow::Factory.instance(@repo_name, :source_control)
      end

    end
  end
end