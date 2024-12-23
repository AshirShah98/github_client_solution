require_relative '../client'
require 'webmock/rspec'

RSpec.describe Github::Client do
  let(:token) { 'test_token' }
  let(:repo_url) { 'https://api.github.com/repos/test/repo' }
  let(:client) { Github::Client.new(token, repo_url) }

  before do
    stub_request(:get, %r{#{repo_url}.*})
      .to_return(
        { status: 200, body: '[{"id":1,"title":"Issue 1"}]', headers: { 'Content-Type' => 'application/json' } },
        { status: 200, body: '[]', headers: { 'Content-Type' => 'application/json', 'Link' => nil } }
      )
  end

  describe '#get' do
    it 'makes a GET request to the provided URL' do
      response = client.get('/issues')
      expect(response.code).to eq(200)
      expect(response.body).to eq('[{"id":1,"title":"Issue 1"}]')
    end
  end

  describe '#get_paginated' do
    it 'fetches all paginated data' do
      stub_request(:get, "#{repo_url}/issues?state=open")
        .to_return(
          { status: 200, body: '[{"id":1,"title":"Issue 1"}]', headers: { 'Link' => '<https://api.github.com/repos/test/repo/issues?page=2>; rel="next"' } },
          { status: 200, body: '[{"id":2,"title":"Issue 2"}]', headers: {} }
        )

      result = client.get_paginated("#{repo_url}/issues?state=open")
      expect(result.size).to eq(2)
      expect(result).to include({ 'id' => 1, 'title' => 'Issue 1' }, { 'id' => 2, 'title' => 'Issue 2' })
    end
  end

  describe '#parse_next_url' do
    it 'parses the next URL from the Link header' do
      link_header = '<https://api.github.com/repos/test/repo/issues?page=2>; rel="next", <https://api.github.com/repos/test/repo/issues?page=3>; rel="last"'
      next_url = client.send(:parse_next_url, link_header)
      expect(next_url).to eq('https://api.github.com/repos/test/repo/issues?page=2')
    end

    it 'returns nil if there is no next URL' do
      link_header = '<https://api.github.com/repos/test/repo/issues?page=3>; rel="last"'
      next_url = client.send(:parse_next_url, link_header)
      expect(next_url).to be_nil
    end
  end
end
