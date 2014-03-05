require 'spec_helper'
require File.join(base_path, 'lib', 'workflow', 'adapters', 'continuous_integration', 'travis')

describe 'Flow::Workflow::Travis' do
  let!(:config)             { { 'url' => 'supu', 'project_name' => 'tupu', 'rebuild_patterns' => rebuild_patterns, 'max_rebuilds' => max_rebuilds }}
  let!(:subject)            { Flow::Workflow::Travis.new(config) }
  let!(:pull_request)       { double('pr', statuses: statuses, branch: 'supu', comments: comments) }
  let!(:statuses)           { [ travis_status ] }
  let!(:travis_status)      { double('travis_status', description: description, state: state) }
  let!(:non_travis_status)  { double('non_travis_status', description: description, state: state) }
  let!(:description)        { 'The Travis CI build bla bla bla' }
  let!(:state)              { 'success' }
  let!(:rebuild_patterns)   { [ 'Errno::ETIMEDOUT' ] }
  let!(:comments)           { [] }
  let!(:max_rebuilds)       { 3 }

  describe '#is_green?' do
    describe 'when pull request build status is success' do
      describe 'and is a travis status' do
        it 'should return true' do
          subject.is_green?(pull_request).should be_true
        end
      end
      describe 'when is not a travis status' do
        let!(:description)  { 'supu' }
        it 'should return false' do
          subject.is_green?(pull_request).should be_false
        end
      end
    end
    describe 'when pull request build status is not success' do
      let!(:statuses)           { [ travis_status, non_travis_status ] }
      let!(:non_travis_status)  { double('non_travis_status', description: 'harl', state: 'failed') }

      let!(:state) { 'failed' }
      it 'should return false' do
        subject.is_green?(pull_request).should be_false
      end
    end
  end

  describe '#is_green?' do
    describe 'when pull request build status is pending' do
      let!(:state) { 'pending' }
      describe 'and is a travis status' do
        it 'should return true' do
          subject.pending?(pull_request).should be_true
        end
      end
      describe 'when is not a travis status' do
        let!(:description)  { 'supu' }
        it 'should return false' do
          subject.is_green?(pull_request).should be_false
        end
      end
    end
    describe 'when pull request build status is not pending' do
      let!(:statuses)           { [ travis_status, non_travis_status ] }
      let!(:non_travis_status)  { double('non_travis_status', description: 'harl', state: 'failed') }

      let!(:state) { 'failed' }
      it 'should return false' do
        subject.is_green?(pull_request).should be_false
      end
    end
  end

  describe '#rebuild!' do
    let!(:first_log)    { 'First log' }
    let!(:second_log)   { 'Second log' }
    let!(:third_log)    { 'Third log' }
    let!(:pattern_log)  { rebuild_patterns.first }
    before do
      subject.stub(:jobs).and_return([ 0, 1, 2 ])
      subject.stub(:restart!).and_return(true)
      subject.stub(:job_log).with(0).and_return(first_log)
      subject.stub(:job_log).with(1).and_return(second_log)
      subject.stub(:job_log).with(2).and_return(third_log)
    end
    after do
      subject.rebuild! pull_request
    end
    describe 'when travis last status is success' do
      it 'should not ask the api for all jobs' do
        expect(subject).to_not receive(:jobs)
      end
      it 'should not call travis api to restart any job' do
        expect(subject).to_not receive(:restart!).with
      end
    end
    describe 'when travis last status is error and max rebuilds has been reached' do
      let!(:state)            { 'error' }
      let!(:comments)         { [ rebuild_comment, rebuild_comment, rebuild_comment ] }
      let!(:rebuild_comment)  { double('rebuild_comment', body: Flow::Workflow::Travis::REBUILD_COMMENT) }
      it 'should not ask the api for all jobs' do
        expect(subject).to_not receive(:jobs)
      end
      it 'should not call travis api to restart any job' do
        expect(subject).to_not receive(:restart!).with
      end
    end
    describe 'when travis last status is not success' do
      let!(:state) { 'failed' }
      before do
        pull_request.stub(:comment!).and_return('')
      end
      it 'should ask the api for all jobs' do
        expect(subject).to receive(:jobs)
      end
      describe 'and any jobs contain rebuild patterns' do
        it 'should not call travis api to restart any job' do
          expect(subject).to_not receive(:restart!).with
        end
        it 'should comment rebuilding on the pull request' do
          expect(pull_request).to_not receive(:comment!)
        end
      end
      describe 'and all jobs contain rebuild patterns' do
        before do
          subject.stub(:job_log).with(0).and_return(pattern_log)
          subject.stub(:job_log).with(1).and_return(pattern_log)
          subject.stub(:job_log).with(2).and_return(pattern_log)
        end
        it 'should call travis api to restart all jobs' do
          expect(subject).to receive(:restart!).with(0)
          expect(subject).to receive(:restart!).with(1)
          expect(subject).to receive(:restart!).with(2)
        end
        it 'should comment rebuilding on the pull request' do
          expect(pull_request).to receive(:comment!)
        end
      end
      describe 'and some jobs contain rebuild patterns' do
        before { subject.stub(:job_log).with(1).and_return(pattern_log) }
        it 'should call travis api to restart the job' do
          expect(subject).to receive(:restart!).with(1)
        end
        it 'should comment rebuilding on the pull request' do
          expect(pull_request).to receive(:comment!)
        end
      end
    end
  end

end