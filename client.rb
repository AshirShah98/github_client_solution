require 'httparty'

module Github
  class Client
    # This class is responsible for making requests to the Github API.
    # It accepts a personal access token and stores it as an instance variable.

    def initialize(token, repo_url)
      @token = token
      @repo_url = repo_url
    end

    def get(url)
      # Makes a GET request to the Github API using the provided URL.
      HTTParty.get("#{@repo_url}#{url}", headers: headers)
    end

    def get_paginated(url)
      # Handles pagination for API requests.
      all_data = []
      loop do
        response = HTTParty.get(url, headers: headers)
        raise "Error: #{response.code} - #{response.body}" unless response.success?

        data = JSON.parse(response.body)
        all_data.concat(data)

        next_url = parse_next_url(response.headers['link'])
        break unless next_url

        url = next_url
      end
      all_data
    end

    private

    def headers
      {
        'Authorization' => "Bearer #{@token}",
        'User-Agent' => 'Github Client'
      }
    end

    def parse_next_url(link_header)
      return nil unless link_header

      links = link_header.split(',').map { |link| link.match(/<(.*?)>; rel="(.*?)"/) }.compact
      next_link = links.find { |_, rel| rel == 'next' }
      next_link ? next_link[1] : nil
    end
  end
end
