require 'spec_helper'
require File.join(base_path, 'lib', 'workflow', 'adapters', 'continuous_integration', 'jenkins')
require File.join(base_path, 'lib', 'workflow', 'models', 'pull_request')


describe 'Flow::Workflow::Jenkins' do

  let!(:config)    { { 'url' => 'supu', 'project_name' => 'tupu' }}
  let!(:subject)  { Flow::Workflow::Jenkins.new(config) }

  describe '#is_green?' do
    let!(:repo)                   { nil }
    let!(:branch)                 { nil }
    let!(:last_stable_build)      { { 'actions' => lsb_actions } }
    let!(:lsb_actions)            { { 1 => { 'buildsByBranchName' => builds_by_branch_name }} }
    let!(:builds_by_branch_name)  { { "origin/#{branch}" => { 'revision' => { 'SHA1' => last_green_commit }}} }
    let!(:last_master_commit)     { 'supu' }
    let!(:last_green_commit)      { 'supu' }
    let!(:pr)                     { Flow::Workflow::PullRequest.new(nil, {}) }

    before do
      pr.stub(:repo_name).and_return(repo)
      pr.stub(:branch).and_return(branch)
      subject.stub(:last_stable_build).and_return(last_stable_build)
      subject.stub(:last_master_commit).and_return(last_master_commit)
    end

    describe 'for a valid jenkins response' do
      describe 'and last master commit is equal to jenkins last green build' do
        it { subject.is_green?(pr).should be_true }
      end
      describe 'and last master commit is different to jenkins last green build' do
        let!(:last_green_commit) { 'tupu' }
        it { subject.is_green?(pr).should_not be_true }
      end
    end

    describe 'for an invalid jenkins response' do
      let!(:last_stable_build) { nil }
      it { subject.is_green?(pr).should be_false }
    end
  end
end