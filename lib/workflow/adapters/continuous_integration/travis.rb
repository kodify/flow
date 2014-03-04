require File.join(File.dirname(__FILE__), 'continuous_integration')

module Flow
  module Workflow
    class Travis < Flow::Workflow::ContinuousIntegration
      @base_url = 'https://api.travis-ci.org/'

      def is_green?(pr)
        @pr = pr
        @__green__ ||= {}
        unless @__green__.include? pr.branch
          @__green__[pr.branch] = build_status? 'success'
        end
        @__green__[pr.branch]
      end

      def pending?(pr)
        @pr = pr
        @__pending__ ||= {}
        unless @__pending__.include? pr.branch
          @__pending__[pr.branch] = build_status? 'pending'
        end
        @__pending__[pr.branch]
      end

      def rebuild!(pr)
        @pr = pr
        return if last_status.state == 'success'

        sw = false
        jobs.each do |job|
          if needs_rebuild? job
            sw = true
            restart! job
          end
        end
        sw
      end

      protected

      def build_status?(state)
        status = last_status
        return unless status
        return status.state == state
      end

      def last_status
        statuses = @pr.statuses
        return unless statuses

        statuses.any? do |state|
          return state if state.description.include? 'The Travis CI'
        end
      end

      def needs_rebuild?(job)
        return unless config['rebuild_patterns']

        log = job_log(job)
        config['rebuild_patterns'].any? do |pattern|
          log.include? pattern
        end
      end

      def build_id
        last_status.target_url.split('/').last
      end

      def jobs
        response = RestClient::Request.new(method: :get, url: "#{@base_url}builds/#{build_id}").execute
        response['build']['job_ids']
      end

      def job_log(job)
        RestClient::Request.new(method: :get, url: "#{@base_url}jobs/#{job}").execute
      end

      def restart!(job)
        RestClient::Request.new(method: :post, url: "#{@base_url}jobs/#{job}/restart").execute
      end

    end
  end
end