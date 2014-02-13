ENV['RACK_ENV'] = 'test'

require 'spec_helper'
require File.join(base_path, 'bin', 'api')
require File.join(base_path, 'lib', 'workflow', 'repo')

describe 'The HelloWorld App' do
  let!(:issue_key) { '0' }
  let!(:repos_number) { Flow::Config.get['projects'].length }

  def app
    Sinatra::Application
  end

  before do
    Flow::Workflow::Repo.any_instance.stub(:pull_request_by_name).and_return(pr)
    Flow::Workflow::Workflow.any_instance.stub(:client).and_return(nil)
  end

  describe "/pr/ok" do
    let!(:pr) { nil }

    before do
      post "/pr/#{issue_key}/ok"
    end

    describe 'with non valid params' do
      it 'should response with a not found code' do
        expect(last_response.status).to eq 404
      end
      it 'should response with an error message' do
        expect(last_response.body).to eq('{"error":"Specified branch does not exist"}')
      end
    end

    describe 'with valid params' do
      let!(:issue_key) { 'WTF-22' }
      describe 'non existing pull request' do
        it 'should response with a not found code' do
          expect(last_response.status).to eq 404
        end
        it 'should response with an error message' do
          expect(last_response.body).to eq('{"error":"Specified branch does not exist"}')
        end
      end

      describe 'existing pull request' do
        let!(:pr) { double('pr', ship_it!: true) }
        before do
          pr.stub(:ship_it!).and_return true
        end
        it 'should response with a success code' do
          expect(last_response.status).to eq 200
        end
        it 'should response with a success message' do
          expect(last_response.body).to eq('"success"')
        end
        it 'should comment with shipit on the pull requests for all repos with this PR' do
          pr.should have_received(:ship_it!).exactly(repos_number).times
        end
      end
    end
  end

  describe "/pr/ko" do
    let!(:pr) { nil }

    before do
      post "/pr/#{issue_key}/ko"
    end

    describe 'with non valid params' do
      it 'should response with a not found code' do
        expect(last_response.status).to eq 404
      end
      it 'should response with an error message' do
        expect(last_response.body).to eq('{"error":"Specified branch does not exist"}')
      end
    end

    describe 'with valid params' do
      let!(:issue_key) { 'WTF-22' }
      describe 'non existing pull request' do
        it 'should response with a not found code' do
          expect(last_response.status).to eq 404
        end
        it 'should response with an error message' do
          expect(last_response.body).to eq('{"error":"Specified branch does not exist"}')
        end
      end

      describe 'existing pull request' do
        let!(:pr) { double('pr', boom_it!: true) }
        before do
          pr.stub(:boom_it!).and_return true
        end
        it 'should response with a success code' do
          expect(last_response.status).to eq 200
        end
        it 'should response with a success message' do
          expect(last_response.body).to eq('"success"')
        end
        it 'should comment with shipit on the pull requests for all repos' do
          pr.should have_received(:boom_it!).exactly(repos_number).times
        end
      end
    end
  end

end