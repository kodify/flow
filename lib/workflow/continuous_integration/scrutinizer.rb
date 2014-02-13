require 'json'
require File.join(File.dirname(__FILE__), 'continuous_integration')


module Flow
  module Workflow
    class Scrutinizer
      extend Flow::Workflow::ContinuousIntegration
      attr_accessor :config

      def initialize(config)
        @config = config
      end

      def is_green?(pr)
        @__green__ ||= {}
        unless @__green__.include? pr.original_branch
          @__green__[pr.original_branch] = begin
            build_green?(pr) && scrutinizer_green?(pr)
          rescue Exception => e
            false
          end
        end
      end

      def pending?(pr)
        last_scrutinizer_github_status(pr) == 'pending'
      end

      protected

      def build_green?(pr)
        status = last_travis_status pr
        return unless status
        return status.state == 'success'
      end

      def scrutinizer_green?(pr)
        metrics = valid_metrics?(pr)
        status  = last_scrutinizer_github_status(pr)
        return unless status

        if !metrics && status.state == 'success'
          pr.comment_not_green
        end

         metrics && status.state == 'success'
      end

      def target_url(pr)
        target = last_scrutinizer_github_status(pr)
        return unless target

        if target.rels[:target].nil?
          ''
        else
          target.rels[:target].href
        end
      end

      def last_status(pr, pattern)
        statuses = pr.statuses
        return unless statuses

        statuses.any? do |state|
          return state if state.description.include? pattern
        end
      end

      def last_travis_status(pr)
        last_status(pr, 'The Travis CI')
      end

      def last_scrutinizer_github_status(pr)
        last_status(pr, 'Scrutinizer')
      end

      def inspection_status(pr)
        return unless url = target_url(pr)
        repo = pr.repo_name
        JSON.parse(`curl #{inspection_url(inspection_uuid(url), repo)}`)
      end

      def inspection_uuid(target_url)
        target_url.slice(target_url.index('inspections'), target_url.size).sub('inspections/', '')
      end

      def inspection_url(uuid, repo)
        "#{url}#{repo}/inspections/#{uuid}?access_token=#{token}"
      end

      def metrics(status)
        status['_embedded']['head_index']['_embedded']['project']['metric_values']
      end

      def valid_metrics?(pr)
        status = inspection_status(pr)
        return unless status
        return if status['state'] == 'failed'

        metrics_on_repo = config['metrics']
        metrics_on_repo.keys.all? do |key|
          metrics(status)[key].to_f > metrics_on_repo[key].to_f
        end
      end

      def url
        config['url']
      end

      def token
        config['token']
      end
    end
  end
end