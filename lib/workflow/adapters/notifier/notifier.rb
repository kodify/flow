require File.join(File.dirname(__FILE__), '..', 'adapter')

module Flow
  module Workflow
    class Notifier < Flow::Workflow::Adapter
      attr_accessor :room

      def initialize(config, options = {})
        super
      end

      def say_green_balls
        say 'Hey master has green balls, lets go for a deploy?!', :notify => true
      end

      def say_big_build_queued
        say 'Big build queued!'
      end

      def say_processing(pr)
        say "Processing: #{pr.branch}"
      end

      def say_merged(pr)
        say "\tMerged (#{pr.number}) and deleted branch #{pr.branch}", 'green'
      end

      def say_cant_merge(pr)
        say "\tCan't merge #{pr.number}, status '#{pr.status.to_s}'"
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