require 'spec_helper'
require File.join(base_path, 'lib', 'workflow', 'adapters', 'continuous_integration', 'scrutinizer')

describe 'Flow::Workflow::ScritinizerNew' do
  let!(:pull_request)   { double('pull_request', statuses: statuses, repo_name: 'my/repo', comment_not_green!: true) }
  let!(:statuses)       { [] }
  let!(:pending)        { double('pending', state: 'pending', description: 'Scrutinizer pending') }
  let!(:success)        { double('success', state: 'success', description: 'Scrutinizer success', rels: rels) }
  let!(:failed)         { double('failed', state: 'failed', description: 'Scrutinizer failed') }
  let!(:success_travis) { double('failed', state: 'success', description: 'Travis') }
  let!(:config)         { { 'url' => 's', 'token' => 'token', 'metrics' => metrics } }
  let!(:metrics)        { { 'pdepend.cyclomatic_complexity_number' => complexity, 'scrutinizer.nb_issues' => issues_number} }
  let!(:issues_number)  { 2 }
  let!(:complexity)     { 2 }
  let!(:rels)           { { target: target} }
  let!(:target)         { double('target', href: 'https://scrutinizer-ci.com/g/owner/repo/inspections/inspectionId' )}
  let!(:subject)        { Flow::Workflow::ScrutinizerNew.new(config) }


  describe '#is_green?' do
    describe 'for a pull request with success status' do
      let!(:build_json) do
        mock_template('scrutinizer', 'build', ':uuid:'    => uuid,
                      ':status:'  => status)
      end
      let!(:uuid)   { 'uuid' }
      let!(:statuses) { [success] }

      before do
        subject.stub(:curl).and_return(build_json)
      end

      describe 'and scrutinizer build status as success' do
        let!(:status) { 'success' }
        describe 'and valid metrics' do
          let!(:issues_number)  { 0 }
          let!(:complexity)     { 0 }
          it { subject.is_green?(pull_request).should be_true }
        end
        describe 'and not valid metrics' do
          let!(:issues_number)  { 999999 }
          let!(:complexity)     { 999999 }
          it { subject.is_green?(pull_request).should be_false }
          it 'should make a comment on the pull request as not green' do
            expect(pull_request).to receive(:comment_not_green!)
            subject.is_green?(pull_request)
          end
        end
      end

      describe 'and scrutinizer build status as failed' do
        let!(:status) { 'failed' }
        it { subject.is_green?(pull_request).should be_false }
        it 'should make a comment on the pull request as not green' do
          expect(pull_request).to receive(:comment_not_green!).with("Pull request marked as #{status} by Scrutinizer")
          subject.is_green?(pull_request)
        end
      end

      describe 'and scrutinizer build status as canceled' do
        let!(:status) { 'canceled' }
        it { subject.is_green?(pull_request).should be_false }
        it 'should make a comment on the pull request as not green' do
          expect(pull_request).to receive(:comment_not_green!).with("Pull request marked as #{status} by Scrutinizer")
          subject.is_green?(pull_request)
        end
      end
    end

    describe 'for a pull request with non success status' do
      let!(:statuses) { [success_travis] }
      it { subject.is_green?(pull_request).should be_false }
    end
  end

  describe '#is_pending?' do
    describe 'for a pull request without Scrutinizer status' do
      let!(:statuses) { [success_travis] }
      it { subject.pending?(pull_request).should be_false }
    end
    describe 'for a pull request with last non pending status' do
      let!(:statuses) { [success, success_travis, pending] }
      it { subject.pending?(pull_request).should be_false }
    end
    describe 'for a pull request with last pending status' do
      let!(:statuses) { [pending, success_travis] }
      it { subject.pending?(pull_request).should be_true }
    end
  end
end