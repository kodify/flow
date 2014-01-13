require 'spec_helper'
require File.join(@@base_path, 'lib', 'workflow', 'pull_request')

describe 'PullRequest' do
  describe '#ignore' do
    let!(:title)      { "#{keyword} me" }
    let!(:client)     { double('client') }
    let!(:repo)       { double('repo') }
    let!(:pull)       { double('pull', title: title) }
    let!(:keyword)    { '[IGNORE]' }
    let!(:dictionary) { { 'ignore' => keyword } }

    let!(:subject)    { Flow::Workflow::PullRequest.new(client, repo, pull) }

    before do
      subject.stub(:dictionary).and_return(dictionary)
    end

    describe 'title contains ignore keyword' do
      it 'should be ignorable' do
        subject.send(:ignore).should be_true
      end
    end

    describe 'title contains ignore keyword' do
      let!(:title) { 'Do not be ignored' }
      it 'should not be ignored' do
        subject.send(:ignore).should be_false
      end
    end
  end
end