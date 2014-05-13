ENV['RACK_ENV'] = 'test'

require 'octokit'
require 'spec_helper'
require File.join(base_path, 'bin', 'api')
require File.join(base_path, 'lib', 'workflow', 'models', 'repo')
require File.join(base_path, 'lib', 'workflow', 'adapters', 'issue_tracker', 'dummy_it')
require File.join(base_path, 'lib', 'workflow', 'adapters', 'notifier', 'dummy_notifier')
require File.join(base_path, 'lib', 'workflow', 'adapters', 'source_control', 'github')

describe 'The FlowAPI' do
  let!(:issue_key)    { '0' }
  let!(:repos_number) { Flow::Config.get['projects'].length }
  let!(:pr)           { nil }
  let!(:token)        { Flow::Config.get['flow']['token'] }

  def app
    Sinatra::Application
  end

  describe '/ping' do
    it 'should respond to ping' do
      get(:ping, { 'token' => token }).body.should eq 'its alive'
    end
  end

  describe 'issue tracker webhooks' do
    before do
      Flow::Workflow::Repo.any_instance.stub(:pull_request_by_name).and_return(pr)
    end

    describe "/pr/ok" do
      before do
        post "/pr/#{issue_key}/ok", { 'token' => token }
      end

      describe 'with non valid params' do
        it 'should response with a not found code' do
          expect(last_response.status).to eq 404
        end
        it 'should response with an error message' do
          expect(last_response.body).to eq('{"error":"Specified branch does not exist"}')
        end
      end

      describe 'with valid params' do
        let!(:issue_key) { 'WTF-22' }
        describe 'non existing pull request' do
          it 'should response with a not found code' do
            expect(last_response.status).to eq 404
          end
          it 'should response with an error message' do
            expect(last_response.body).to eq('{"error":"Specified branch does not exist"}')
          end
        end

        describe 'existing pull request' do
          let!(:pr) { double('pr', ship_it!: true) }
          before do
            pr.stub(:ship_it!).and_return true
          end
          it 'should response with a success code' do
            expect(last_response.status).to eq 200
          end
          it 'should response with a success message' do
            expect(last_response.body).to eq('"success"')
          end
          it 'should comment with shipit on the pull requests for all repos with this PR' do
            pr.should have_received(:ship_it!).exactly(repos_number).times
          end
        end
      end
    end

    describe "/pr/ko" do
      before do
        post "/pr/#{issue_key}/ko", { 'token' => token }
      end

      describe 'with non valid params' do
        it 'should response with a not found code' do
          expect(last_response.status).to eq 404
        end
        it 'should response with an error message' do
          expect(last_response.body).to eq('{"error":"Specified branch does not exist"}')
        end
      end

      describe 'with valid params' do
        let!(:issue_key) { 'WTF-22' }
        describe 'non existing pull request' do
          it 'should response with a not found code' do
            expect(last_response.status).to eq 404
          end
          it 'should response with an error message' do
            expect(last_response.body).to eq('{"error":"Specified branch does not exist"}')
          end
        end

        describe 'existing pull request' do
          let!(:pr) { double('pr', boom_it!: true) }
          before do
            pr.stub(:boom_it!).and_return true
          end
          it 'should response with a success code' do
            expect(last_response.status).to eq 200
          end
          it 'should response with a success message' do
            expect(last_response.body).to eq('"success"')
          end
          it 'should comment with shipit on the pull requests for all repos' do
            pr.should have_received(:boom_it!).exactly(repos_number).times
          end
        end
      end
    end
  end

  describe 'when a webhook calls payload' do
    let!(:event)        { '' }
    let!(:payload)      { '' }
    let!(:body)         { 'Hello' }
    let!(:id)           { 'ID' }
    let!(:number)       { 100 }
    let!(:pull_request) { double('pull_request',
                                 id: 1,
                                 head: pull_request_head,
                                 title: 'hello',
                                 number: number,
                                 rels: { comments: comments_getter } ) }
    let!(:branch)             { 'name' }
    let!(:pull_request_head)  { double('head', attrs: { sha: sha }, label: "branch:#{branch}") }
    let!(:sha)                { 'xxxx' }
    let!(:comments_getter)    { double('comments_getter', get: comments_data )}
    let!(:comments_data)      { double('comments_data', data: comments)}
    let!(:comments)           { [ ] }
    let!(:comment_reviewed)   { double('reviewed', body: config['dictionary']['reviewed'].first) }
    let!(:comment_uat_ko)     { double('uat_ko', body: config['dictionary']['uat_ko'].first) }
    let!(:comment_uat_ok)     { double('uat_ok', body: config['dictionary']['uat_ok'].first) }
    let!(:event)    { 'issue_comment' }
    let!(:payload)  { mock_template('github', 'issue_comment', ':comment_body:' => body, ':repo_name:' => repo, ':pull_request_number:' => number.to_s) }
    let!(:body)     { 'Hello' }
    let!(:repo)     { config['projects'].keys.first }
    let!(:merge_response)   { true }
    let!(:octokit_response) { double('octokit_response', attrs: { :merged => merge_response } ) }

    before do
      Octokit::Client.any_instance.stub(:pull_request).and_return(pull_request)
      Octokit::Client.any_instance.stub(:add_comment).and_return(true)
      Flow::Workflow::DummyIt.any_instance.stub(:branch_to_id).and_return id
    end

    after do
      post '/payload', { payload: payload, 'token' => token }, {'HTTP_X_GITHUB_EVENT' => event}
    end

    describe 'with pull_request event' do
      let!(:event)    { 'pull_request' }
      let!(:payload)  { mock_template('github', 'pull_request', ':repo_name:' => repo, ':pull_request_number:' => number.to_s, ':sha:' => sha) }
      before do
        Flow::Workflow::Github.any_instance.stub(:pull_request_from_request).and_return(pull_request)
        Flow::Workflow::Github.any_instance.stub(:clean_repo).and_return true
        Flow::Workflow::Github.any_instance.stub(:put_branch_on_path).and_return true
        Flow::Workflow::Github.any_instance.stub(:create_branch_on_path).and_return true
        Flow::Workflow::Github.any_instance.stub(:create_pull_request).and_return true
        Flow::Workflow::Github.any_instance.stub(:clone_project_into).and_return true
      end
      #describe 'And NOT dependent repos related' do
      #  let!(:pull_request) {Flow::Workflow::PullRequest.new(Flow::Workflow::Repo.new(repo),{})}
      #  it 'should NOT create a pull request to related repository' do
      #    expect_any_instance_of(Flow::Workflow::PullRequest).to receive(:treat_dependent)
      #    expect_any_instance_of(Flow::Workflow::Repo).not_to receive(:create_pull_request)
      #  end
      #end
      describe 'And some dependent repos related' do
        let!(:pull_request) {Flow::Workflow::PullRequest.new(Flow::Workflow::Repo.new(repo),{})}
        before do
          config['projects'].values.first['source_control']['github']['dependent_repos'] = [{name: "kodify/repo1", path: "/submodule_path"}]
        end

        it 'should create a pull request to related repository' do
          expect_any_instance_of(Flow::Workflow::PullRequest).to receive(:treat_dependent)
          expect_any_instance_of(Flow::Workflow::Repo).to receive(:create_pull_request)
        end
      end

    end
  end


end