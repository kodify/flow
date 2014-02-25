require 'hipchat'
require File.join(File.dirname(__FILE__), 'notifier')

module Flow
  module Workflow
    class Hipchat < Flow::Workflow::Notifier

      def initialize(config, options = {})
        super
        @thor   = options[:thor]
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

      def say_params_not_on_prod
        msg = "All those params doesn't seem to be in prod environment"
        say(msg, :notify => true)
      end

      def say_deploy_aborted_by_params
        msg = 'DEPLOY ABORTED! Apply changes to parameters.yml'
        say(msg, :notify => true)
      end

      def say(msg, options = {})
        say_on_room(default_user, msg, options)
        # @thor.say str
      end

      def say_on_room(user, message, options = {})
        if working_hours?
          client[room].send(user, message, options)
        end
      end

      def working_hours?
        return false unless @config['days'].to_s.include? week_day.to_s

        hours = @config['hours'].split('-')

        return false if hours.first.to_i > current_hour
        return false if hours.last.to_i < current_hour

        true
      end

      def week_day
        Time.now.wday
      end

      def current_hour
        Time.now.hour
      end

      def default_user
        @config['default_user']
      end

      def room
        @room ||= @config['room']
      end

      def client
        HipChat::Client.new(@config['token'])
      end

      def random_user
        [ 'Rocco Siffredi', 'Jenna haze', 'Bridget The Midget', 'Eve Angel', 'Eva Angelina',
          'Alexis Texas', 'Jayden James', ' Lexi Belle', 'Phoenix Marie', 'Lisa Ann', 'Honeysuckle',
          'Morning Glory', 'Peach Blossom', 'Beachcomber', 'Tiddly Wink', 'Tra La La',
          'Rarity', 'Pinkie Pie', 'Rainbox Dash', 'Fluttershy'
        ].sample
      end
    end
  end
end