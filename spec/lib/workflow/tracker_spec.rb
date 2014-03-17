require 'spec_helper'
require File.join(base_path, 'lib', 'workflow', 'tracker')

describe 'Flow::Workflow::Tracker' do

  let!(:subject) { Flow::Workflow::Tracker.new }

  describe '#uat_bottlenecks' do
    let!(:issues) { [] }
    let!(:issue)  { double('issue', html_link: 'h_link') }
    before do
      Flow::Workflow::DummyIt.any_instance.stub(:unassigned_issues_by_status).and_return(issues)
      Flow::Workflow::DummyIt.any_instance.stub(:min_unassigned_uats).and_return(2)
    end

    after do
      subject.uat_bottlenecks
    end

    describe 'non unassigned issues on uat' do
      it 'should do nothing' do
        expect_any_instance_of(Flow::Workflow::DummyNotifier).to_not receive(:say_uat_bottlenecks)
      end
    end

    describe 'less than permitted unassigned issues on uat' do
      let!(:issues) { [issue] }
      it 'should do nothing' do
        expect_any_instance_of(Flow::Workflow::DummyNotifier).to_not receive(:say_uat_bottlenecks)
      end
    end

    describe 'more than permitted unassigned issues on uat' do
      let!(:issues) { [issue, issue, issue] }
      it 'should notify for bottlenecks' do
        expect_any_instance_of(Flow::Workflow::DummyNotifier).to receive(:say_uat_bottlenecks)
      end
    end
  end

  describe '#review_bottlenecks' do
    let!(:pull_requests) { [] }
    let!(:pull_request)  { double('pull_request',
                                 branch: 'branch',
                                 text_link: 'link',
                                 html_link: 'html_link',
                                 reviewed?: false,
                                 ignore?: false,
                                 blocked?: false) }

    before do
      Flow::Workflow::Repo.any_instance.stub(:pull_requests).and_return(pull_requests)
    end

    after do
      subject.review_bottlenecks
    end

    describe 'non pending review open pull requests' do
      it 'should do nothing' do
        expect_any_instance_of(Flow::Workflow::DummyNotifier).to_not receive(:say)
      end
    end

    describe 'less than max permitted non reviewed pull requests' do
      let(:pull_requests) { [pull_request] }
      it 'should do nothing' do
        expect_any_instance_of(Flow::Workflow::DummyNotifier).to_not receive(:say)
      end
    end

    describe 'more than permitted unassigned issues on uat' do
      let(:pull_requests) { [pull_request, pull_request, pull_request] }
      it 'should notify for review' do
        expect_any_instance_of(Flow::Workflow::DummyNotifier).to receive(:say)
      end
    end
  end

end