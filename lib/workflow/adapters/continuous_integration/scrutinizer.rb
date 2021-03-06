require 'json'
require File.join(File.dirname(__FILE__), 'continuous_integration')


module Flow
  module Workflow
    class Scrutinizer < Flow::Workflow::ContinuousIntegration

      def is_green?(pr)
        @pr = pr
        return false unless success_status?
        return valid_metrics?
      end

      def pending?(pr)
        @pr = pr
        pending_status?
      end

      protected

      def pending_status?
        current_scrutinizer_state == 'pending'
      end

      def success_status?
        current_scrutinizer_state == 'success'
      end

      def current_scrutinizer_state
        current_scrutinizer_status.state if current_scrutinizer_status.respond_to? 'state'
      end

      def current_scrutinizer_status
        @pr.statuses.each do |status|
          return status if status.description.include? 'Scrutinizer'
        end
      end

      def valid_metrics?
        status = request_build_info['state']
        #FIXME : Canceled stuff is a temporary fix reevaluate it on 25 March 2014
        if ['failed'].include? status
          @pr.comment_not_green! "Pull request marked as #{status} by Scrutinizer"
          return false
        elsif invalid_metrics.empty? || 'canceled' == status
          return true
        else
          send_metrics_report
          return false
        end
      end

      def invalid_metrics
        invalid = {}
        config['metrics'].keys.each do |type|
          metrics   = config['metrics'][type].to_s.split
          metrics.unshift('>=') if metrics.length <= 1
          build     = build_metrics[type].to_f
          if build.method(metrics.first).(metrics.last.to_f)
            invalid[type] = { expected: config['metrics'][type].to_f, reported: build_metrics[type].to_f }
          end
        end
        invalid
      end

      def build_metrics
        request_build_info['_embedded']['repository']['applications']['master']['index']['_embedded']['project']['metric_values']
      end

      def request_build_info
        @__inspection_status__ ||= begin
          url   = current_scrutinizer_status.rels[:target].href
          uuid  = url.slice(url.index('inspections'), url.size).sub('inspections/', '')

          url = "#{config['url']}#{@pr.repo_name}/inspections/#{uuid}?access_token=#{config['token']}"

          JSON.parse(curl(url))
        end
      end

      def send_metrics_report
        unless invalid_metrics.empty?
          report = "\nMetric | Max. Expected | Your Results\r\n";
          report << "--- | --- | ---\r\n";
          invalid_metrics.each do |key, value|
            report <<  "#{key} | #{value[:expected]} | #{value[:reported]}\r\n"
          end
          report << "\n"
        end
        @pr.comment_not_green! report if !report.empty?
      end

      def build_metric(type)
        request_build_info['_embedded']['repository']['applications']['master']['index']['_embedded']['project']['metric_values'][type]
      end

      def curl(url)
        `curl -s #{url}`
      end
    end
  end
end