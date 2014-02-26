require 'hipchat'
require File.join(File.dirname(__FILE__), 'notifier')

module Flow
  module Workflow
    class Hipchat < Flow::Workflow::Notifier

      def initialize(config, options = {})
        super
        @thor   = options[:thor]
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

    end
  end
end