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
      Flow::Workflow::Github.any_instance.stub(:clean_repo).and_return true
      Flow::Workflow::Github.any_instance.stub(:put_branch_on_path).and_return true
      Flow::Workflow::Github.any_instance.stub(:create_branch_on_path).and_return true
      Flow::Workflow::Github.any_instance.stub(:create_pull_request).and_return true
      Flow::Workflow::Github.any_instance.stub(:clone_project_into).and_return true
    end

    after do
      post '/payload', { payload: payload, 'token' => token }, {'HTTP_X_GITHUB_EVENT' => event}
    end

    describe 'with pull_request event' do
      let!(:event)    { 'pull_request' }
      let!(:payload)  { mock_template('github', 'pull_request', ':repo_name:' => repo, ':pull_request_number:' => number.to_s, ':sha:' => sha) }
      before do
        Flow::Workflow::Github.any_instance.stub(:clean_repo)
        Flow::Workflow::Github.any_instance.stub(:put_branch_on_path)
        Flow::Workflow::Github.any_instance.stub(:create_branch_on_path)
        Flow::Workflow::Github.any_instance.stub(:create_pull_request)
        Flow::Workflow::Github.any_instance.stub(:clone_project_into)
      end
      describe 'And NOT dependent repos related' do
        let!(:pull_request) {Flow::Workflow::PullRequest.new(Flow::Workflow::Repo.new(repo),{})}
        before do
          Flow::Workflow::Github.any_instance.stub(:pull_request_from_request).and_return(pull_request)
        end
        it 'should NOT create a pull request to related repository' do
          expect_any_instance_of(Flow::Workflow::PullRequest).to receive(:treat_dependent)
          expect_any_instance_of(Flow::Workflow::Repo).not_to receive(:create_pull_request)
        end
      end
      describe 'And some dependent repos related' do
        before do
          repoToUse = Flow::Workflow::Repo.new(repo)
          pull_request = Flow::Workflow::PullRequest.new(repoToUse,{})
          Flow::Workflow::Github.any_instance.stub(:pull_request_from_request).and_return(pull_request)

          config['projects'].values.first['source_control']['github']['dependent_repos'] = [{'name' => "kodify/repo1", 'path' => "/submodule_path"}]
        end

        it 'should create a pull request to related repository' do
          #expect_any_instance_of(Flow::Workflow::PullRequest).to receive(:treat_dependent)
          expect_any_instance_of(Flow::Workflow::Repo).to receive(:clone_into)
          expect_any_instance_of(Flow::Workflow::Repo).to receive(:create_pull_request)
        end
      end

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
            expect_any_instance_of(Flow::Workflow::DummyNotifier).to receive(:cant_flow)
          end
          it 'should not do merge' do
            expect_any_instance_of(Flow::Workflow::PullRequest).to_not receive(:merge)
          end
        end
        describe 'and a previous blocker comment on the pull request' do
          let!(:comments) { [ comment_reviewed, comment_uat_ko ] }
          it 'should say unmergeable' do
            expect_any_instance_of(Flow::Workflow::DummyNotifier).to receive(:cant_flow)
          end
          it 'should not do merge' do
            expect_any_instance_of(Flow::Workflow::PullRequest).to_not receive(:merge)
          end
        end
        describe 'and pull request has another related pull request' do
          let!(:related_pull_request) { double('related', status: related_status) }
          let!(:related_repos)        { [ Flow::Config.get['projects'].keys.first ] }
          let!(:related_status)       { :not_reviewed }
          before do
            Octokit::Client.any_instance.stub(:pull_requests).and_return([])
            Flow::Workflow::Github.any_instance.stub(:configured_related_repos).and_return(related_repos)
            Flow::Workflow::Repo.any_instance.stub(:pull_request_by_name).and_return(related_pull_request)
          end
          describe 'and a related pull request not reviewed' do
            it 'should say unmergeable' do
              expect_any_instance_of(Flow::Workflow::DummyNotifier).to receive(:cant_flow)
            end
            it 'should not do merge' do
              expect_any_instance_of(Flow::Workflow::PullRequest).to_not receive(:merge)
            end
          end
          describe 'and a related pull request is already reviewed' do
            let!(:related_status)       { :success }
            it 'should say unmergeable' do
              expect_any_instance_of(Flow::Workflow::DummyNotifier).to receive(:cant_flow)
            end
            it 'should not do merge' do
              expect_any_instance_of(Flow::Workflow::PullRequest).to_not receive(:merge)
            end
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

      describe 'and comment body has a uat ok comment' do
        let!(:body)             { config['dictionary']['uat_ok'].first }
        let!(:pull_requests)    { [ pull_request ] }
        let!(:comments)         { [ comment_uat_ok, comment_reviewed ] }

        before do
          Octokit::Client.any_instance.stub(:pull_requests).and_return(pull_requests)
          Octokit::Client.any_instance.stub(:merge_pull_request).and_return(octokit_response)
          Octokit::Client.any_instance.stub(:delete_ref).and_return true
          Flow::Workflow::PullRequest.any_instance.stub(:all_repos_on_status?).with(:not_uat).and_return(true)
          Flow::Workflow::PullRequest.any_instance.stub(:all_repos_on_status?).with(:success).and_return(true)
        end

        describe 'when pull request is success' do
          describe 'and has non success related pull requests' do
            before do
              Flow::Workflow::PullRequest.any_instance.stub(:all_repos_on_status?).with(:success).and_return(false)
            end
            it 'should not move issue to done on the issue tracker' do
              expect_any_instance_of(Flow::Workflow::DummyIt).to_not receive(:do_move).with(:done, id)
            end
          end
          describe 'and has success related pull requests' do
            before do
              Flow::Workflow::PullRequest.any_instance.stub(:all_repos_on_status?).with(:success).and_return(true)
            end
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
            describe "and can't merge pull request" do
              before do
                Flow::Workflow::PullRequest.any_instance.stub(:merge).and_return(false)
              end
              it 'should move the issue to in progress' do
                expect_any_instance_of(Flow::Workflow::DummyIt).to receive(:do_move).with(:uat_nok, id)
              end
              it 'should block the pull request' do
                expect_any_instance_of(Flow::Workflow::PullRequest).to receive(:block_it!).with("Can't automerge this pull request")
              end
            end
          end
        end

        describe 'when pull request is not success' do
          let!(:comments)  { [ comment_reviewed ] }
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
            expect_any_instance_of(Flow::Workflow::DummyNotifier).to receive(:say_merge_failed)
          end
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

      describe 'when error or success pull request' do
        let!(:pull_requests)    { [ pull_request ] }
        let!(:comments)         { [ comment_reviewed, comment_uat_ok ] }
        let!(:merge_response)   { true }

        before do
          Octokit::Client.any_instance.stub(:pull_requests).and_return(pull_requests)
          Octokit::Client.any_instance.stub(:merge_pull_request).and_return(octokit_response)
          Octokit::Client.any_instance.stub(:delete_ref).and_return true
        end

        describe 'reporting an error status' do
          let!(:state)            { 'error' }
          before do
            Flow::Workflow::Travis.any_instance.stub(:jobs).and_return([ 0, 1, 2 ])
            Flow::Workflow::Travis.any_instance.stub(:restart!).and_return(true)
            Flow::Workflow::Travis.any_instance.stub(:job_log).with(0).and_return('xxx')
          end
          it 'should not move the pull request' do
            expect_any_instance_of(Flow::Workflow::PullRequest).to_not receive(:move_away!)
          end
          it 'should try to rebuild' do
            expect_any_instance_of(Flow::Workflow::PullRequest).to receive(:rebuild!)
          end
        end

        describe 'reporting a success status' do
          let!(:state)            { 'success' }
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
              expect_any_instance_of(Flow::Workflow::DummyNotifier).to receive(:say_merge_failed)
            end
          end

        end
      end
    end
  end


end