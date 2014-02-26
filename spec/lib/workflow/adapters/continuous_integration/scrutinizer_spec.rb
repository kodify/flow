require 'spec_helper'
require File.join(base_path, 'lib', 'workflow', 'adapters', 'continuous_integration', 'scrutinizer')
require File.join(base_path, 'lib', 'workflow', 'pull_request')

describe 'Flow::Workflow:Scrutinizer' do
  let!(:config) do
    {
      'url'   => 'url',
      'token' => 'token',
      'metrics' => {
          'pdepend.cyclomatic_complexity_number'  => '127',
          'scrutinizer.quality'                   => '7,6',
          'scrutinizer.nb_issues'                 => '1514',

      }
    }
  end
  let!(:subject) do
    Flow::Workflow::Scrutinizer.new(config)
  end
  let!(:repo)                   { nil }
  let!(:branch)                 { nil }
  let!(:target_url)             { nil }
  let!(:inspection_status)      { {} }
  let!(:metrics)                { }
  let!(:last_status)            { }
  let!(:pr)                     { Flow::Workflow::PullRequest }
  let!(:statuses)               { { } }

  before do
    pr.stub(:repo_name).and_return(repo)
    pr.stub(:branch).and_return(branch)
    pr.stub(:target_url).and_return(target_url)
    pr.stub(:statuses).and_return(statuses)
  end

  describe '#is_green?' do
    before do
      subject.stub(:inspection_status).and_return(inspection_status)
      subject.stub(:config).and_return(config)
      subject.stub(:metrics).and_return(metrics)
      subject.stub(:last_status).and_return(last_status)
    end
    describe 'when an invalid target_url is given' do
      let!(:repo)                   { 'kodify/supu' }
      it { subject.is_green?(pr).should be_false }
    end

    describe 'when an invalid repo is given' do
      let!(:target_url)             { 'http://www.supu.com' }
      it { subject.is_green?(pr).should be_false }
    end

    describe 'for a valid input data' do
      let!(:repo)                   { 'kodify/supu' }
      let!(:branch)                 { nil }
      let!(:target_url)             { 'http://www.supu.com' }
      describe 'for an invalid scrutinizer response' do
        it { subject.is_green?(pr).should be_false }
      end
      describe 'and a valid scrutinizer response' do
        describe 'and unexpected response' do
          it { subject.is_green?(pr).should be_false }
        end
        describe 'and failed status' do
          let!(:inspection_status)      { { 'state' => 'failed'} }
          it { subject.is_green?(pr).should be_false }
        end
        describe 'and no statuses for this pull request' do
          let!(:inspection_status)      { { 'state' => 'failed'} }
          it { subject.is_green?(pr).should be_false }
        end
        describe 'and expected response' do
          let!(:inspection_status)      { { 'state' => 'success'} }
          let!(:last_status)            { Object.new }

          let!(:metrics) do
            {
              'pdepend.cyclomatic_complexity_number'  => '120',
              'scrutinizer.quality'                   => '7',
              'scrutinizer.nb_issues'                 => '1500',
            }
          end

          before do
            last_status.stub(:description).and_return 'The Travis CI'
            last_status.stub(:state).and_return 'success'
          end

          it { subject.is_green?(pr).should be_true }
        end
      end
    end
  end

  describe '#pending?' do
    let!(:pending_status) { double('pending_status', description: 'Scrutinizer', state: 'pending') }
    let!(:failed_status) { double('pending_status', description: 'Scrutinizer', state: 'failed') }
    let!(:success_status) { double('pending_status', description: 'Scrutinizer', state: 'success') }

    describe 'when no scrutinizer status for this pull request' do
      let!(:statuses) { [] }
      it {  subject.pending?(pr).should be_false }
    end
    describe 'when no scrutinizer pending status for this pull request' do
      let!(:statuses) { [success_status, failed_status] }
      it {  subject.pending?(pr).should be_false }
    end
    describe 'when pending status is not the last status' do
      let!(:statuses) { [failed_status, pending_status] }
      it { subject.pending?(pr).should be_false }
    end
    describe 'when pending status is the last status' do
      let!(:statuses) { [pending_status, failed_status] }
      it { subject.pending?(pr).should be_true }
    end
  end


end