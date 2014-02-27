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

  def app
    Sinatra::Application
  end

  describe '/ping' do
    it 'should respond to ping' do
      get(:ping).body.should eq 'its alive'
    end
  end

  describe 'issue tracker webhooks' do
    before do
      Flow::Workflow::Repo.any_instance.stub(:pull_request_by_name).and_return(pr)
    end

    describe "/pr/ok" do
      before do
        post "/pr/#{issue_key}/ok"
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
        post "/pr/#{issue_key}/ko"
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

  describe 'when a webhook call payload' do
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

    before do
      Octokit::Client.any_instance.stub(:pull_request).and_return(pull_request)
      Flow::Workflow::DummyIt.any_instance.stub(:branch_to_id).and_return id
    end

    after do
      post '/payload', { payload: payload }, {'HTTP_X_GITHUB_EVENT' => event}
    end

    describe 'with issue_comment event' do

      describe 'and comment body non matching any special pattern' do
        it 'should do nothing' do
          expect_any_instance_of(Flow::Workflow::PullRequest).to_not receive(:uat_ko?)
        end
      end

      describe 'and comment body has a code review ok comment' do
        let!(:body)     { config['dictionary']['reviewed'].first }
        let!(:comments) { [ comment_reviewed ] }
        let!(:move_to)  { :ready_uat }
        describe 'and no previous blocker comments on the pull request' do
          it 'should move issue to in progress' do
            expect_any_instance_of(Flow::Workflow::DummyIt).to receive(:do_move).with(move_to, id)
          end
        end
        describe 'and a previous uat_ko comments on the pull request' do
          let!(:comments) { [ comment_reviewed, comment_uat_ko ] }
          it 'should say unmergeable' do
            expect_any_instance_of(Flow::Workflow::DummyNotifier).to receive(:say_cant_merge)
          end
        end
        describe 'and a previous blocker comment on the pull request' do
          let!(:comments) { [ comment_reviewed, comment_uat_ko ] }
          it 'should say unmergeable' do
            expect_any_instance_of(Flow::Workflow::DummyNotifier).to receive(:say_cant_merge)
          end
        end
      end

      describe 'and comment body has a blocker comment' do
        let!(:body) { config['dictionary']['blocked'].first }
        it 'should notify pull request owner'
        it 'should exit without doing any query' do
          expect_any_instance_of(Flow::Workflow::PullRequest).to_not receive(:uat_ko?)
        end
      end

      describe 'and comment body has a uat ko comment' do
        let!(:body)     { config['dictionary']['uat_ko'].first }
        let!(:move_to)  { :in_progress }
        let!(:comments) { [ comment_reviewed ] }
        it 'should exit without doing any query' do
          expect_any_instance_of(Flow::Workflow::PullRequest).to_not receive(:uat_ko?)
        end
      end
    end

    describe 'with status event' do
      let!(:event)    { 'status' }
      let!(:payload)  { mock_template('github', 'status_update', ':state:' => state, ':repo:' => repo, ':pull_request_number:' => number.to_s, ':sha:' => sha) }
      let!(:state)    { 'Hello' }
      let!(:repo)     { config['projects'].keys.first }

      ['pending', 'success', 'failure'].each do |state|
        describe "reporting a #{state} status" do
          it 'should do nothing' do
            expect_any_instance_of(Flow::Workflow::PullRequest).to_not receive(:move_away!)
          end
        end
      end

      describe 'reporting a success status' do
        let!(:state)            { 'success' }
        let!(:pull_requests)    { [ pull_request ] }
        let!(:comments)         { [ comment_reviewed, comment_uat_ok ] }
        let!(:merge_response)   { true }

        before do
          Octokit::Client.any_instance.stub(:pull_requests).and_return(pull_requests)
          Octokit::Client.any_instance.stub(:merge_pull_request).and_return({ 'merged' => merge_response })
          Octokit::Client.any_instance.stub(:delete_ref).and_return true
        end

        describe 'when pull request is success' do
          it 'should merge the pull request' do
            expect_any_instance_of(Octokit::Client).to receive(:merge_pull_request).with(repo, number, "#{branch} #UAT-OK - PR #{number} merged")
          end
          it 'should remove the pull request related branch' do
            expect_any_instance_of(Octokit::Client).to receive(:delete_ref).with(repo, "heads/#{branch}")
          end
          it 'should move issue to done on the issue tracker' do
            expect_any_instance_of(Flow::Workflow::DummyIt).to receive(:do_move).with(:done, id)
          end
          it 'should notify branch is merged' do
            expect_any_instance_of(Flow::Workflow::DummyNotifier).to receive(:say_merged)
          end
        end

        describe 'when pull request is not success' do
          let!(:state) { 'failed' }
          it 'should not merge the pull request' do
            expect_any_instance_of(Octokit::Client).to_not receive(:merge_pull_request).with(repo, number, "#{branch} #UAT-OK - PR #{number} merged")
          end
          it 'should not remove the pull request related branch' do
            expect_any_instance_of(Octokit::Client).to_not receive(:delete_ref).with(repo, "heads/#{branch}")
          end
          it 'should not move issue to done on the issue tracker' do
            expect_any_instance_of(Flow::Workflow::DummyIt).to_not receive(:do_move).with(:done, id)
          end
          it 'should not notify branch is merged' do
            expect_any_instance_of(Flow::Workflow::DummyNotifier).to_not receive(:say_merged)
          end
        end

        describe 'when pull request is not mergeable' do
          let!(:merge_response) { false }
          it 'should try to merge the pull request' do
            expect_any_instance_of(Octokit::Client).to receive(:merge_pull_request).with(repo, number, "#{branch} #UAT-OK - PR #{number} merged")
          end
          it 'should not remove the pull request related branch' do
            expect_any_instance_of(Octokit::Client).to_not receive(:delete_ref).with(repo, "heads/#{branch}")
          end
          it 'should not move issue to done on the issue tracker' do
            expect_any_instance_of(Flow::Workflow::DummyIt).to_not receive(:do_move).with(:done, id)
          end
          it 'should not notify branch is merged' do
            expect_any_instance_of(Flow::Workflow::DummyNotifier).to_not receive(:say_merged)
          end
          it "should notify branch can't be merged" do
            expect_any_instance_of(Flow::Workflow::DummyNotifier).to receive(:say_cant_merge)
          end
        end

      end
    end
  end


end