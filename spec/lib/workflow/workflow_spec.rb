require 'spec_helper'
require File.join(@@base_path, 'lib', 'workflow', 'workflow')

describe Flow::Workflow::Workflow do

  describe '#integrate_pull_request' do
    let!(:pr)       { double('pr', merge: merge, to_done: nil, delete_original_branch: nil) }
    let!(:notifier) { double('notifier', say_merged: nil, say_big_build_queued: nil, say_cant_merge: nil) }
    let!(:merge)    { true }

    before do
      subject.stub(:big_build).and_return(nil)
      subject.__notifier__ = notifier
      subject.send(:integrate_pull_request, pr)
    end

    it 'should do the merge' do
      pr.should have_received(:merge)
    end

    describe 'for a valid github response' do
      it 'should delete original branch' do
        pr.should have_received(:delete_original_branch)
      end
      it 'should mark pr as done' do
        pr.should have_received(:to_done)
      end
      it { should have_received(:big_build) }
      it { notifier.should have_received(:say_merged) }
      it { notifier.should have_received(:say_big_build_queued) }
    end

    describe 'for an invalid github response' do
      let!(:merge) { false }

      it 'should say can not merge' do
        notifier.should have_received(:say_cant_merge)
      end
    end
  end

  describe '#flow' do

    let!(:repo_name)      { 'supu' }
    let!(:all_prs)        { [ pr ] }
    let!(:status)         { :success }
    let!(:config)         { { 'flow' => { 'pending_pr_to_notify' => pending_pr, 'pending_pr_interval_in_sec' => interval } } }
    let!(:interval)       { 1 }
    let!(:pending_pr)     { 10 }
    let!(:octokit_client) { double('octokit_client') }
    let!(:notifier)       { double('notifier', say_processing: nil) }
    let!(:pr) do
      double('pr', {
          status: status,
          to_in_progress: true,
          to_uat: true,
          save_comments_to_be_discussed: true,
      } )
    end

    before do
      subject.stub(:open_pull_requests).and_return all_prs
      subject.stub(:big_build).and_return true
      subject.stub(:config).and_return config
      subject.stub(:octokit_client).and_return octokit_client
      subject.stub(:notifier).and_return notifier
      subject.stub(:integrate_pull_request).and_return true
      subject.stub(:ask_for_reviews).and_return true

      subject.flow(repo_name)
    end

    it 'should say processing' do
      notifier.should have_received(:say_processing)
    end

    describe 'for a success pull request' do
      it 'integrate this pull request' do
        subject.should have_received(:integrate_pull_request)
      end
    end

    describe 'for a uat_ko pull request' do
      let!(:status) { :uat_ko }
      it 'pull request should be moved to in progress' do
        pr.should have_received(:to_in_progress)
      end
    end

    describe 'for a non uated pull request' do
      let!(:status) { :not_uat }
      it 'pull request should be moved to uat' do
        pr.should have_received(:to_uat)
      end
    end

    describe 'for a not reviewed pull request' do
      let!(:pending_pr) { 1 }
      let!(:status)     { :not_reviewed }
      it 'should ask for notify pull requests' do
        subject.should have_received(:ask_for_reviews)
      end
    end

  end

end