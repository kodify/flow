require 'spec_helper'


describe 'Flow::Workflow::Notifier' do

  let!(:thor)     { nil }
  let!(:subject)  { Flow::Workflow::Notifier.new(thor) }

  describe '#working_hours?' do
    let!(:days)         { '12345' }
    let!(:hours)        { '9-19'}
    let!(:config)       { { 'hours' => hours, 'days' => days } }

    before do
      subject.stub(:config).and_return(config)
      subject.stub(:week_day).and_return(week_day)
      subject.stub(:current_hour).and_return(current_hour)
    end

    describe 'for a day/hour inside the config range' do
      let!(:week_day)     { 1 }
      let!(:current_hour) { 14 }
      it 'should be in working hours' do
        subject.working_hours?.should be_true
      end
    end

    describe 'for a day inside config range and hour outside' do
      let!(:week_day)     { 1 }
      let!(:current_hour) { 5 }
      it 'should not be in working hours' do
        subject.working_hours?.should be_false
      end
    end

    describe 'for a day inside config range and hour outside' do
      let!(:week_day)     { 0 }
      let!(:current_hour) { 13 }
      it 'should not be in working hours' do
        subject.working_hours?.should be_false
      end
    end
  end
end