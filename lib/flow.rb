require 'rubygems'
require 'thor'

require File.join(File.dirname(__FILE__), 'config')
require File.join(File.dirname(__FILE__), 'workflow/jenkins')

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
    require File.join(File.dirname(__FILE__), 'workflow/workflow')

    workflow = Flow::Workflow::Workflow.new self
    workflow.flow repo
  end

  desc 'can_deploy', 'Notify kodify room if deploy is available or not'
  def can_deploy(repo, branch = 'master')
    jenkins = Ambrosio::Workflow::Jenkins.new
    if jenkins.is_green?(repo, branch)
      notifier.say_green_balls
    end
  end

  protected

  def notifier
    @__notifier__ ||= Flow::Workflow::Notifier.new self
  end

end

Kod.start