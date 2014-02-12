require 'json'
require File.join(File.dirname(__FILE__), 'continuous_integration')


module Flow
  module Workflow
    class Scrutinizer
      extend Flow::Workflow::ContinuousIntegration

      def is_green?(repo, branch, target_url)
        status = inspection_status(target_url, repo)
        return false if status['state'] == 'failed'

        metrics_on_repo = metrics_to_check(repo)
        metrics_on_repo.keys.each do |key|
          return false if metrics(status)[key].to_f < metrics_on_repo[key].to_f
        end
        true
      end

      protected

      def inspection_status(url,repo)
        JSON.parse(`curl #{inspection_url(inspection_uuid(url),repo)}`)
      end

      def inspection_uuid(target_url)
        target_url.slice(target_url.index('inspections'),target_url.size).sub('inspections/','')
      end

      def last_master_commit(repo, branch = 'master')
        `git ls-remote "git@github.com:#{repo}.git" |grep "refs/heads/#{branch}$"`.split(' ')[0]
      end

      def url
        Flow::Config.get['scrutinizer']['url']
      end

      def token
        Flow::Config.get['scrutinizer']['token']
      end

      def inspection_url(uuid, repo)
        return "#{url}#{repo}/inspections/#{uuid}?access_token=#{token}"
      end

      def metrics(status)
        status['_embedded']['head_index']['_embedded']['project']['metric_values']
      end

      def metrics_to_check(repo)
        Flow::Config.get['projects'][repo]['metrics']
      end

    end
  end
end