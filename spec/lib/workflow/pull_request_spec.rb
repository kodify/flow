require 'spec_helper'
require File.join(base_path, 'lib', 'workflow', 'pull_request')

describe 'PullRequest' do
  let!(:scm)     { double('client') }
  let!(:repo)       { double('repo') }
  let!(:pull)       { double('pull', title: title) }
  let!(:keyword)    { '' }
  let!(:title)      { "#{keyword} me" }

  let!(:subject) do
    Flow::Workflow::PullRequest.new(repo,
                    id:         '1',
                    sha:        'sha',
                    title:      title,
                    number:     'number',
                    branch:     'branch',
                    comments:   [ 'a', 'b' ],
    )

  end

  describe '#ignore?' do
    let!(:keyword)    { '[IGNORE]' }
    let!(:dictionary) { { 'ignore' => keyword } }

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
    let!(:jira_id)      { 'WTF-111' }
    let!(:success)      { double('success_pr', status: :success) }
    let!(:uat_ko)       { double('success_pr', status: :uat_ko) }
    let!(:repo1)        { double('repo1') }
    let!(:repo2)        { double('repo1') }
    let!(:pulls_repo1)  { nil }
    let!(:pulls_repo2)  { nil }
    let!(:repos)        { [repo1, repo2] }
    before do
      repo1.stub(:pull_request_by_name).and_return(pulls_repo1)
      repo2.stub(:pull_request_by_name).and_return(pulls_repo2)
      subject.stub(:jira_id).and_return(jira_id)
    end
    describe 'when repos does not contain any pull request with this id' do
      it 'should be true' do
        subject.send(:all_repos_on_status?, repos).should be_true
      end
    end
    describe 'when repos contain a pull request with this id and it is success' do
      let!(:pulls_repo1) { success }
      let!(:pulls_repo2) { nil }
      it 'should be true' do
        subject.send(:all_repos_on_status?, repos).should be_true
      end
    end
    describe 'when repos contain a pull request with this id and it is not success' do
      let!(:pulls_repo1) { success }
      let!(:pulls_repo2) { uat_ko }
      it 'should be true' do
        subject.send(:all_repos_on_status?, repos).should be_false
      end
    end
  end
end