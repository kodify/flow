require 'spec_helper'
require File.join(base_path, 'lib', 'workflow', 'repo')
require File.join(base_path, 'lib', 'workflow', 'pull_request')

describe 'Repo' do
  let!(:name)     { 'supu' }
  let!(:subject)  { Flow::Workflow::Repo.new(name) }
  let!(:scm)      { Object.new }
  let!(:pullA)    { double('pullA', head: { label: 'supu:pullA' }, issue_tracker_id: 'PULL-A' ) }
  let!(:pullB)    { double('pullB', head: { label: 'supu:pullA' }, issue_tracker_id: 'PULL-B' ) }
  let!(:pullC)    { double('pullC', head: { label: 'supu:pullA' }, issue_tracker_id: 'PULL-C' ) }
  let!(:pulls)    { [pullA, pullB, pullC] }
  let!(:issueA)   { double('issueA', title: 'A') }
  let!(:issueB)   { double('issueB', title: 'B') }
  let!(:issueC)   { double('issueC', title: 'C') }
  let!(:issues)   { [issueA, issueB, issueC] }

  before do
    scm.stub(:pull_requests).and_return(pulls)
    scm.stub(:issues).and_return(issues)
    subject.stub(:scm).and_return(scm)
  end

  describe '#pull_request_by_name' do
    describe 'when searching an existing pull request' do
      it { subject.pull_request_by_name(pullA.head[:label].split(':')[1]).should.equal? pullA }
    end
    describe 'when searching a non existing pull request' do
      it { subject.pull_request_by_name('unexisting').should be_nil }
    end
  end

  describe '#issue_exists' do
    describe 'when searching an existing pull request' do
      it { subject.issue_exists(issueA.title).should be_true }
    end
    describe 'when searching a non existing pull request' do
      it { subject.issue_exists('unexisting').should be_false }
    end
  end

  describe '#issue!' do
    describe 'given a valid title' do
      let!(:title) { 'supu_title'}
      before do
        scm.stub(:create_issue).with(name, title, '', {}).and_return(true)
      end
      it { subject.issue!(title).should be_true }
    end
    describe 'given a valid title' do
      it { subject.issue!(issueA.title).should be_nil }
    end
  end

end