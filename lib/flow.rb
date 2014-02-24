require 'rubygems'
require 'thor'

require File.join(File.dirname(__FILE__), 'config')
require File.join(File.dirname(__FILE__), 'workflow/factory')
require File.join(File.dirname(__FILE__), 'workflow/workflow')

def current_path
  @current_path ||= File.expand_path(File.dirname(__FILE__) + '/..')
end

class Kod < Thor
  include Thor::Actions

  desc 'flow', <<E
KodiFlow:
To be executed periodically, this will apply kodiflow over the given repository.

kod flow <repo_name>

E
  def flow(repo)
    workflow = Flow::Workflow::Workflow.new self
    workflow.flow repo
  end

  desc 'can_deploy', 'Notify kodify room if deploy is available or not'
  def can_deploy(repo, branch = 'master')
    ci_instance = ci(repo)
    if ci_instance.is_green?(repo, branch)
      notifier.say_green_balls
    end
  end

  desc 'uat_checker', 'Alert of unassigned uat message'
  def uat_checker
    issues = issue_tracker.issues_by_status('UAT')
    issues_unassigned_on_uat = []
    html_message = ""

    issues.each do |issue|
      if issue['fields']['assignee'].nil?
        url = "#{issue_tracker.url}#{issue['key']}/browse/"
        html_message += "<br /> <a href='#{url}'>#{issue['key']}</a> -  #{issue['fields']['summary']}"
        issues_unassigned_on_uat << issue['fields']['assignee']
      end
    end

    if issues_unassigned_on_uat.length >= issue_tracker.min_unassigned_uats
      html_message = "There are #{issues_unassigned_on_uat.length} PR ready to be uated in #{@repo_name} repo: #{html_message}"
      notifier.room = config['projects'].first[1]['not']['uat_room']
      notifier.say html_message, :notify => true, :message_format => 'html'
    end
  end

  protected

  def ci(repo)
    Flow::Workflow::Factory.instance(repo, :continuous_integration)
  end

  def issue_tracker(repo = config['projects'].keys.first)
    @__it__ ||= Flow::Workflow::Factory.instance(repo, :issue_tracker)
  end

  def notifier(repo = config['projects'].keys.first)
    @__notifier__ ||= Flow::Workflow::Factory.instance(repo, :notifier, thor: self)
  end

  def config
    @__config__ ||= Flow::Config.get
  end

end

Kod.start
