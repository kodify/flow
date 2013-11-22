require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 9494

path = File.expand_path(File.dirname(__FILE__) + '/..')

require path + '/lib/workflow/jenkins'

require File.join(path, 'lib', 'config')
require File.join(path, 'lib', 'workflow', 'repo')
require File.join(path, 'lib', 'workflow', 'workflow')

post '/pr/:issue/ko' do
  move_pr :boom_it!
end

post'/pr/:issue/ok' do
  move_pr :ship_it!
end

get '/ping' do
  'its alive'
end


helpers do
  def valid_deploy?(params)
    jenkins = Flow::Workflow::Jenkins.new
    !(params[:branch] == 'production' && !jenkins.is_green?(params[:repo], params[:branch]))
  end

  def move_pr(method)
    status 404
    response = { error: 'Specified branch does not exist' }
    repos.each do |repo_name|
      if (pr = pull_request(repo_name, params[:issue]))
        pr.send method
        status 200
        response = :success
      end
    end
    json response
  end

  def pull_request(repo_name, issue_key)
    repo = Flow::Workflow::Repo.new(github_client, repo_name)
    repo.pull_request_by_name(issue_key)
  end

  def github_client
    @__github_client__ ||= begin
      workflow = Flow::Workflow::Workflow.new
      workflow.client
    end
  end

  def repos
    Flow::Config.get['github']['valid_repos']
  end

end

