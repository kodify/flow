require File.join(File.dirname(__FILE__), '..', 'adapter')

module Flow
  module Workflow
    class Notifier < Flow::Workflow::Adapter
      attr_accessor :room

      def initialize(config, options = {})
        super
      end

      def say_uat_bottlenecks(count, list)
        message = "There are #{count} PR ready to be uated: #{list}"
        say_on_uat_room(default_user, message, options = {})
      end

      def say_green_balls
        say 'Hey master has green balls, lets go for a deploy?!', :notify => true
      end

      def say_moved(issue, status)
        say "Issue #{issue} moved to status #{status}", :notify => true
      end

      def cant_flow(issue, status)
        say "Issue #{issue} can't flow, status #{status}", :notify => true, :color => 'red'
      end

      def say_merge_failed(issue)
        say "Issue #{issue} can't be merged, please rebase it", :notify => true, :color => 'red'
      end

      def say_merged(issue, branch)
        say "\tMerged issue (#{issue}) and deleted related branch #{branch}", :notify => true, :color => 'green'
      end

      def say_big_build_queued
        say 'Big build queued!'
      end

      def say_processing(pr)
        say "Processing: #{pr.branch}"
      end

      def say_cant_merge(pr)
        say "\tCan't merge #{pr.number}, status '#{pr.status.to_s}'"
      end

      def say_rebuild(pr)
        say "#{pr.repo_name}::#{pr.branch} was rebuild through a build error"
      end

      def say(msg, options = {})
      end

      def say_on_room(user, message, options = {})
      end

      def say_on_uat_room(user, message, options)
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