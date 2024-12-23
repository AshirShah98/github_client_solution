require_relative '../client'
require_relative '../process'
require 'webmock/rspec'

RSpec.describe Github::Processor do
  let(:token) { 'test_token' }
  let(:repo_url) { 'https://api.github.com/repos/test/repo' }
  let(:client) { Github::Client.new(token, repo_url) }
  let(:processor) { Github::Processor.new(client) }

  before do
    stub_request(:get, %r{#{repo_url}/issues.*})
      .to_return(
        { status: 200, body: '[{"id":1,"title":"Issue 1","state":"open","created_at":"2024-01-01"}]', headers: {} }
      )
  end

  describe '#issues' do
    it 'fetches and sorts issues by creation date' do
      expect { processor.issues(open: true) }.to output(/Issue 1 - open - Created at: 2024-01-01/).to_stdout
    end
  end

  describe '#project_issues' do
    it 'fetches and sorts project issues using GraphQL' do
      stub_request(:post, "https://api.github.com/graphql")
        .to_return(
          status: 200,
          body: {
            data: {
              node: {
                items: {
                  nodes: [
                    { content: { title: 'Issue 1', state: 'open', createdAt: '2024-01-01', sprintPoints: 5 } },
                    { content: { title: 'Issue 2', state: 'closed', createdAt: '2023-12-01', sprintPoints: 3 } }
                  ]
                }
              }
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { processor.project_issues('project_id') }
        .to output(/Issue 1 - open - Sprint Points: 5/).to_stdout
    end
  end
end
