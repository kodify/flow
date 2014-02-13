require 'json'
require File.join(File.dirname(__FILE__), 'continuous_integration')

module Flow
  module Workflow
    class Jenkins
      extend Flow::Workflow::ContinuousIntegration
      attr_accessor :config

      def initialize(config)
        @config = config
      end

      def is_green?(pr)
        @__green__ ||= {}
        unless @__green__.include? pr.original_branch
          @__green__[pr.original_branch] = begin
            master_commit = last_master_commit(pr.repo_name, pr.original_branch)
            return true if master_commit.nil?
            master_commit == last_stable_commit(pr.original_branch)
          end
        end
      end

      protected

      def last_master_commit(repo, branch = 'master')
        `git ls-remote "git@github.com:#{repo}.git" |grep "refs/heads/#{branch}$"`.split(' ')[0]
      end

      def last_stable_commit(branch)
        if last_stable_build
          if last_stable_build['actions'][1]['buildsByBranchName']["origin/#{branch}"]
            last_stable_build['actions'][1]['buildsByBranchName']["origin/#{branch}"]['revision']['SHA1']
          end
        end
      end

      def last_stable_build
        @__last_stable_build__ ||= JSON.parse(`curl #{config['url']}/lastStableBuild/api/json`)
      rescue
      end
    end
  end
end