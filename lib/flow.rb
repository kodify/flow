require 'rubygems'
require 'thor'

require File.join(File.dirname(__FILE__), 'workflow/tracker')

def current_path
  @current_path ||= File.expand_path(File.dirname(__FILE__) + '/..')
end

class Kod < Thor
  include Thor::Actions

  desc 'review_bottleneck_tracker', 'Track and notify of possible bottlenecks on our workflow'
  def review_bottleneck_tracker
    Flow::Workflow::Tracker.new.review_bottlenecks
  end


  desc 'uat_checker', 'Alert of unassigned uat message'
  def uat_checker
    Flow::Workflow::Tracker.new.uat_bottlenecks
  end

end

Kod.start
