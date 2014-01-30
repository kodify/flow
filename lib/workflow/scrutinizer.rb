require 'json'

module Flow
  module Workflow
    class Scrutinizer

      def is_green?(repo, branch, target_url)
        status = inspection_status(target_url, repo)
        return false if status['state'] == 'failed'

        metrics_on_repo = metrics_to_check(repo)
        metrics_on_repo.keys.each do |key|
          return false if metrics(status)[key].to_f < metrics_on_repo[key].to_f
        end
        true
      end

      def inspection_status(url,repo)
        JSON.parse(`curl #{inspection_url(inspection_uuid(url),repo)}`)
        #JSON.parse(`curl "https://scrutinizer-ci.com/api/repositories/g/natxo-kodify/DownloaderBundle/inspections/91d802d1-dc25-4c95-81a9-ebaeb673d245?access_token=afe4cee555a3823e71935cfecfdf49437c5d1bd3fd6d8e247331255194583ea0"`)
      end

      def inspection_uuid(target_url)
        target_url.slice(target_url.index('inspections'),target_url.size).sub('inspections/','')
      end

      def last_master_commit(repo, branch = 'master')
        `git ls-remote "git@github.com:#{repo}.git" |grep "refs/heads/#{branch}$"`.split(' ')[0]
      end

      def last_stable_commit(branch)
        if last_stable_build
          last_stable_build['actions'][1]['buildsByBranchName']["origin/#{branch}"]['revision']['SHA1']
        end
      end

      def last_stable_build
        @__last_stable_build__ = JSON.parse(`curl #{url}/fux/lastStableBuild/api/json`)
      end

      def big_build(project)
        stop_in_progress_build project
        `curl -X POST #{url}/#{project}/build`
      end

      def stop_in_progress_build(project)
        job = JSON.parse(`curl #{url}/#{project}/lastBuild/api/json`)
        if job['result'] == nil
          `curl -X POST #{url}/#{project}/#{job['number']}/stop`
        end
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