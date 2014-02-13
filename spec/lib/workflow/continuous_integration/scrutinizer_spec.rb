require 'spec_helper'
require File.join(@@base_path, 'lib', 'workflow', 'continuous_integration', 'scrutinizer')

describe 'Flow::Workflow:Scrutinizer' do
  let!(:subject)  { Flow::Workflow::Scrutinizer.new }

  describe '#is_green?' do
    let!(:repo)                   { nil }
    let!(:branch)                 { nil }
    let!(:target_url)             { nil }
    let!(:inspection_status)      { {} }
    let!(:metrics)                { }
    let!(:config) do
      {
          'scrutinizer' => {
              'url'   => 'url',
              'token' => 'token'
          },
          'projects' => {
              repo  => {
                  'metrics' => {
                      'pdepend.cyclomatic_complexity_number'  => '127',
                      'scrutinizer.quality'                   => '7,6',
                      'scrutinizer.nb_issues'                 => '1514',

                  }
              }
          }
      }
    end

    before do
      subject.stub(:inspection_status).and_return(inspection_status)
      subject.stub(:config).and_return(config)
      subject.stub(:metrics).and_return(metrics)
    end

    describe 'when an invalid target_url is given' do
      let!(:repo)                   { 'kodify/supu' }
      it { subject.is_green?(repo, branch, target_url).should be_false }
    end

    describe 'when an invalid repo is given' do
      let!(:target_url)             { 'http://www.supu.com' }
      it { subject.is_green?(repo, branch, target_url).should be_false }
    end

    describe 'for a valid input data' do
      let!(:repo)                   { 'kodify/supu' }
      let!(:branch)                 { nil }
      let!(:target_url)             { 'http://www.supu.com' }
      describe 'for an invalid scrutinizer response' do
        it { subject.is_green?(repo, branch, target_url).should be_false }
      end
      describe 'and a valid scrutinizer response' do
        describe 'and unexpected response' do
          it { subject.is_green?(repo, branch, target_url).should be_false }
        end
        describe 'and failed status' do
          let!(:inspection_status)      { { 'state' => 'failed'} }
          it { subject.is_green?(repo, branch, target_url).should be_false }
        end
        describe 'and expected response' do
          let!(:inspection_status)      { { 'state' => 'success'} }
          let!(:metrics) do
            {
              'pdepend.cyclomatic_complexity_number'  => '200',
              'scrutinizer.quality'                   => '10',
              'scrutinizer.nb_issues'                 => '2000',
            }
          end
          it { subject.is_green?(repo, branch, target_url).should be_true }
        end
      end
    end
  end
end