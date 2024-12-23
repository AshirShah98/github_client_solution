require_relative './client.rb'
require 'json'

module Github
  class Processor
    # This class processes responses from the Github API.

    def initialize(client)
      @client = client
    end

    def issues(open: true)
      # Returns a list of issues from the Github API with pagination support.
      state = open ? 'open' : 'closed'
      url = "#{@client.repo_url}/issues?state=#{state}&per_page=50"

      all_issues = @client.get_paginated(url)
      sorted_issues = all_issues.sort_by do |issue|
        state == 'closed' ? issue['closed_at'] : issue['created_at']
      end.reverse

      sorted_issues.each do |issue|
        if issue['state'] == 'closed'
          puts "#{issue['title']} - #{issue['state']} - Closed at: #{issue['closed_at']}"
        else
          puts "#{issue['title']} - #{issue['state']} - Created at: #{issue['created_at']}"
        end
      end
    end

    def project_issues(project_id)
      # Fetch and sort issues from a project using the GraphQL API.
      query = <<-GRAPHQL
        {
          node(id: "#{project_id}") {
            ... on Project {
              items(first: 100) {
                nodes {
                  content {
                    ... on Issue {
                      title
                      createdAt
                      state
                      sprintPoints: number
                    }
                  }
                }
              }
            }
          }
        }
      GRAPHQL

      response = @client.graphql(query)
      issues = response['data']['node']['items']['nodes']
      sorted_issues = issues.sort_by { |issue| issue['content']['createdAt'] }

      sorted_issues.each do |issue|
        content = issue['content']
        puts "#{content['title']} - #{content['state']} - Sprint Points: #{content['sprintPoints']}"
      end
    end
  end
end

# Usage example:
processor = Github::Processor.new(Github::Client.new(ENV['TOKEN'], ARGV[0]))
processor.issues(open: false)
# Uncomment below to test project issues (replace `project_id` with actual ID)
# processor.project_issues('project_id')
