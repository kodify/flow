require 'sinatra'
require 'sinatra/json'
require 'json'

set :port, 9494

path = File.expand_path(File.dirname(__FILE__) + '/..')

require File.join(path, 'lib', 'config')
require File.join(path, 'lib', 'workflow', 'models', 'repo')
require File.join(path, 'lib', 'workflow', 'push')

before do
  halt 403 unless params.include? 'token'
  halt 403 unless Flow::Config.get['flow']['token'] == params['token']
end

post '/payload' do
  unless params.empty?
    request = JSON.parse(params[:payload])
    push    = Flow::Workflow::Push.new request['repository']['full_name']
    case env['HTTP_X_GITHUB_EVENT']
      when 'issue_comment'
        push.new_comment request
      when 'status'
        push.status_update request
      when 'pull_request'
        if (push.new_pr request)
          status 200
          response = :success
          json response
        end
      else
        puts 'not implemented'
    end
  end
end

post '/pr/:issue/ko' do
  move_pr :boom_it!
end

post '/pr/:issue/ok' do
  move_pr :ship_it!
end

post '/issue/:issue/merged' do
  move_ticket_to_done
end

get '/ping' do
  'its alive'
end


helpers do

  def move_ticket_to_done
    repos.each do |repo_name|
      if (pr = pull_request(repo_name, params[:issue]))
        pr.to_done!
        break
      end
    end
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
    repo = Flow::Workflow::Repo.new(repo_name)
    pr = repo.pull_request_by_name(issue_key)
    pr = repo.pull_request_by_name_closed(issue_key) if !pr
    pr
  end

  def repos
    Flow::Config.get['projects'].keys
  end

end

