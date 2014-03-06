require File.join(File.dirname(__FILE__), 'continuous_integration')

module Flow
  module Workflow
    class Travis < Flow::Workflow::ContinuousIntegration
      REBUILD_COMMENT = '[REBUILDING WITH TRAVIS]'
      BASE_URL        = 'https://api.travis-ci.org/'

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
        last = last_status.state
        return if last == 'success'
        return if last == 'error' && !can_rebuild?

        sw = false
        logs = ''
        jobs.each do |job|
          if needs_rebuild? job
            sw = true
            clear_cache! pr
            restart! job
            logs = "```sh\n#{job_log(job)}\n```"
          end
        end
        @pr.comment! "#{REBUILD_COMMENT} \n #{logs}" if sw
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

      def can_rebuild?
        count = 0
        @pr.comments.each do |comment|
          count += 1 if comment.body.include? REBUILD_COMMENT
        end
        count < config['max_rebuilds']
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
        response = RestClient::Request.new(method: :get, url: "#{BASE_URL}builds/#{build_id}").execute
        response['build']['job_ids']
      end

      def job_log(job)
        @log ||= {}
        @log[job] ||= RestClient::Request.new(method: :get, url: "#{BASE_URL}jobs/#{job}").execute
      end

      def restart!(job)
        RestClient::Request.new(method: :post, url: "#{BASE_URL}jobs/#{job}/restart").execute
      end

      def clear_cache!(pr)
        split_repo = pr.repo_name.split '/'
        RestClient::Request.new(method: :delete, url: "#{BASE_URL}repos/#{split_repo.first}/#{split_repo.last}/caches").execute
      end

    end
  end
end