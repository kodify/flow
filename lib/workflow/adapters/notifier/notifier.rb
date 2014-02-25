require File.join(File.dirname(__FILE__), '..', 'adapter')

module Flow
  module Workflow
    class Notifier < Flow::Workflow::Adapter
      attr_accessor :room

      def initialize(config, options = {})
        super
      end

      def say_green_balls
      end

      def say_big_build_queued
      end

      def say_processing(pr)
      end

      def say_merged(pr)
      end

      def say_cant_merge(pr)
      end

      def say_params_not_on_prod
      end

      def say_deploy_aborted_by_params
      end

      def say(msg, options = {})
      end

      def say_on_room(user, message, options = {})
      end

      def working_hours?
      end

      def week_day
      end

      def current_hour
      end

      def default_user
      end
    end
  end
end