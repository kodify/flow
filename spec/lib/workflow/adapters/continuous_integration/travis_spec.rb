require 'spec_helper'
require File.join(base_path, 'lib', 'workflow', 'adapters', 'continuous_integration', 'travis')

describe 'Flow::Workflow::Travis' do
  let!(:config)             { { 'url' => 'supu', 'project_name' => 'tupu' }}
  let!(:subject)            { Flow::Workflow::Travis.new(config) }
  let!(:pull_request)       { double('pr', statuses: statuses, branch: 'supu') }
  let!(:statuses)           { [ travis_status ] }
  let!(:travis_status)      { double('travis_status', description: description, state: state) }
  let!(:non_travis_status)  { double('non_travis_status', description: description, state: state) }
  let!(:description)        { 'The Travis CI build bla bla bla' }
  let!(:state)              { 'success' }

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

end