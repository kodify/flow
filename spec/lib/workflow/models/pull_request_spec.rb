require 'spec_helper'
require File.join(base_path, 'lib', 'workflow', 'models', 'pull_request')

describe 'PullRequest' do
  let!(:scm)        { double('client') }
  let!(:repo)       { double('repo', related_repos: repos, name: 'repo') }
  let!(:repos)      { [] }
  let!(:pull)       { double('pull', title: title) }
  let!(:keyword)    { '' }
  let!(:title)      { "#{keyword} me" }
  let!(:comment_a)  { double('comment', body: 'a' )}
  let!(:comment_b)  { double('comment', body: 'b' )}

  let!(:subject) do
    Flow::Workflow::PullRequest.new(repo,
                    id:         '1',
                    sha:        'sha',
                    title:      title,
                    number:     'number',
                    branch:     'branch',
                    comments:   [ comment_a, comment_b ],
    )
  end

  describe '#ignore?' do
    let!(:keyword)    { '[IGNORE]' }
    let!(:dictionary) { { 'ignore' => [ keyword ] } }

    before do
      subject.stub(:dictionary).and_return(dictionary)
    end

    describe 'title contains ignore keyword' do
      it 'should be ignorable' do
        subject.send(:ignore?).should be_true
      end
    end

    describe 'title contains ignore keyword' do
      let!(:title) { 'Do not be ignored' }
      it 'should not be ignored' do
        subject.send(:ignore?).should be_false
      end
    end
  end

  describe '#all_repos_on_status?' do
    let!(:issue_tracker_id)      { 'WTF-111' }
    let!(:success)      { double('success_pr', status: :success) }
    let!(:uat_ko)       { double('success_pr', status: :uat_ko) }
    let!(:repo1)        { double('repo1', name: 'repo1') }
    let!(:repo2)        { double('repo2', name: 'repo2') }
    let!(:pulls_repo1)  { nil }
    let!(:pulls_repo2)  { nil }
    let!(:repos)        { [repo1, repo2] }
    let!(:ci)           { double('ci', pending?: false, is_green?: true) }
    before do
      repo1.stub(:pull_request_by_name).and_return(pulls_repo1)
      repo2.stub(:pull_request_by_name).and_return(pulls_repo2)
      subject.stub(:issue_tracker_id).and_return(issue_tracker_id)
      subject.stub(:ci).and_return(ci)
      subject.stub(:status).and_return(:success)
    end
    describe 'when related repos does not contain any pull request with this id' do
      it 'should be true' do
        subject.send(:all_repos_on_status?, :success).should be_true
      end
    end
    describe 'when related repos contain a pull request with this id and it is success' do
      let!(:pulls_repo1) { success }
      let!(:pulls_repo2) { nil }
      it 'should be true' do
        subject.send(:all_repos_on_status?, :success).should be_true
      end
    end
    describe 'when repos contain a pull request with this id and it is not success' do
      let!(:pulls_repo1) { success }
      let!(:pulls_repo2) { uat_ko }
      it 'should be true' do
        subject.send(:all_repos_on_status?, :success).should be_false
      end
    end
  end
end