require 'json'
require File.join(File.dirname(__FILE__), 'continuous_integration')


module Flow
  module Workflow
    class Scrutinizer < Flow::Workflow::ContinuousIntegration

      def is_green?(pr)
        @__green__ ||= {}
        unless @__green__.include? pr.branch
          @__green__[pr.branch] = begin
            green?(pr)
          rescue Exception => e
            false
          end
        end
      end

      def pending?(pr)
        last_scrutinizer_github_status(pr) == 'pending'
      end

      protected

      def green?(pr)
        metrics             = valid_metrics?(pr)
        status              = last_scrutinizer_github_status(pr)
        scrutinizer_status  = inspection_status(pr)
        return unless status
        return unless scrutinizer_status

        comment = ''
        if !metrics && status.state == 'success'
          comment << "\n Metrics doesn't accomplish the configuration : \n\n #{metrics_report(pr)}"
        end

        if ['failed', 'canceled'].include? scrutinizer_status['state']
          url = scrutinizer_status['_links']['self']['href'].gsub('/api/repositories/', 'https://scrutinizer-ci.com/')
          comment << "Current scrutinizer status - **#{scrutinizer_status['state']}** \n\n Relaunch it at (#{url}) or die!"
        end

        pr.comment_not_green comment if !comment.empty?

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

      def last_scrutinizer_github_status(pr)
        last_status(pr, 'Scrutinizer')
      end

      def inspection_status(pr)
        return ['state' => 'not_started'] unless url = target_url(pr)
        repo = pr.repo_name
        @__inspection_status__ ||= JSON.parse(`curl #{inspection_url(inspection_uuid(url), repo)}`)
      end

      def inspection_uuid(target_url)
        target_url.slice(target_url.index('inspections'), target_url.size).sub('inspections/', '')
      end

      def inspection_url(uuid, repo)
        "#{url}#{repo}/inspections/#{uuid}?access_token=#{token}"
      end

      def metrics(status)
        status['_embedded']['repository']['applications']['master']['index']['_embedded']['project']['metric_values']
      end

      def valid_metrics?(pr)
        status = inspection_status(pr)

        return if ['failed', 'canceled'].include? status['state']

        metrics_on_repo = config['metrics']
        metrics_on_repo.keys.all? do |key|
          metrics(status)[key].to_f <= metrics_on_repo[key].to_f
        end
      end

      def metrics_report(pr)
        status = inspection_status(pr)
        return unless status

        report = "Metric | Max. Expected | Your Results\r\n";
        report << "--- | --- | ---\r\n";
        metrics_on_repo = config['metrics']
        metrics_on_repo.keys.each do |key|
          report <<  "#{key} | #{metrics_on_repo[key].to_f} | #{metrics(status)[key].to_f}\r\n"
        end
        report << "\n"
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