require 'json'
require File.join(File.dirname(__FILE__), 'continuous_integration')

module Flow
  module Workflow
    class Jenkins
      extend Flow::Workflow::ContinuousIntegration

      def is_green?(repo, branch, target_url = {})
        master_commit = last_master_commit(repo, branch)
        return true if master_commit.nil?
        master_commit == last_stable_commit(branch)
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
        @__last_stable_build__ ||= JSON.parse(`curl #{url}/fux/lastStableBuild/api/json`)
      end

      def big_build(project)
        stop_in_progress_build project
        `curl -X POST #{url}/#{project}/build`
      end

      def stop_in_progress_build(project)
        job = JSON.parse(`curl #{url}#{project}/lastBuild/api/json`)
        if job['result'] == nil
          `curl -X POST #{url}/#{project}/#{job['number']}/stop`
        end
      end

      def url
        Flow::Config.get['jenkins']['url']
      end
    end
  end
end