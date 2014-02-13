require 'json'
require File.join(File.dirname(__FILE__), 'continuous_integration')


module Flow
  module Workflow
    class Scrutinizer
      extend Flow::Workflow::ContinuousIntegration

      def is_green?(repo, branch, target_url)
        status = inspection_status(target_url, repo)
        return true if status['state'] != 'failed' && metrics_are_valid(repo, status)
      rescue
      end

      protected

      def inspection_status(url, repo)
        JSON.parse(`curl #{inspection_url(inspection_uuid(url), repo)}`)
      end

      def inspection_uuid(target_url)
        target_url.slice(target_url.index('inspections'),target_url.size).sub('inspections/','')
      end

      def inspection_url(uuid, repo)
        "#{url}#{repo}/inspections/#{uuid}?access_token=#{token}"
      end

      def metrics(status)
        status['_embedded']['head_index']['_embedded']['project']['metric_values']
      end

      def metrics_are_valid(repo, status)
        metrics_on_repo = metrics_to_check(repo)
        metrics_on_repo.keys.all? do |key|
          metrics(status)[key].to_f > metrics_on_repo[key].to_f
        end
      end

      def url
        config['scrutinizer']['url']
      end

      def token
        config['scrutinizer']['token']
      end

      def metrics_to_check(repo)
        config['projects'][repo]['metrics']
      end

      def config
        @__config__ ||= Flow::Config.get
      end
    end
  end
end