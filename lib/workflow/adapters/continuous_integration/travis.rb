module Flow
  module Workflow
    class Travis < Flow::Workflow::ContinuousIntegration
      def is_green?(pr)
        @__green__ ||= {}
        unless @__green__.include? pr.branch
          @__green__[pr.branch] = build_status? pr, 'success'
        end
      end

      def pending?(pr)
        @__pending__ ||= {}
        unless @__pending__.include? pr.branch
          @__pending__[pr.branch] = build_status? pr, 'pending'
        end
      end

      protected

      def build_status?(pr, state)
        status = last_status pr
        return unless status
        return status.state == state
      end

      def last_status(pr)
        statuses = pr.statuses
        return unless statuses

        statuses.any? do |state|
          return state if state.description.include? 'The Travis CI'
        end
      end
    end
  end
end