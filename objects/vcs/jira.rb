# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'jira-ruby'
require_relative '../git_repo'

#
# Jira VCS
#
class JiraRepo
  attr_reader :repo, :name

  def initialize(client, json, config = {})
    @name = 'JIRA'
    @client = client
    @config = config
    @json = json
    @repo = git_repo(json, config)
  end

  def issue(issue_id)
    @client.Issue.find(issue_id)
  end

  def close_issue(issue_id)
    issue = @client.Issue.find(issue_id)
    issue.save(
      'fields' => {
        'summary' => data[:description],
        'project' => { 'id' => data[:repo] },
        'issuetype' => { 'id' => '3' },
        'status' => 'closed'
      }
    )
    issue.fetch
  end

  def create_issue(data)
    issue = @client.Issue.build
    issue.save(
      'fields' => {
        'summary' => data[:description],
        'project' => { 'id' => data[:repo] },
        'issuetype' => { 'id' => '3' }
      }
    )
    issue.fetch
  end

  def update_issue(issue_id, data)
    issue = @client.Issue.find(issue_id)
    issue.save(
      'fields' => {
        'summary' => data[:description],
        'project' => { 'id' => data[:repo] },
        'issuetype' => { 'id' => '3' }
      }
    )
    issue.fetch
  end

  def exists?
    @client.Project.find(@repo.name)
    true
  rescue JIRA::NotFound => e
    puts "Repository #{@repo.name} is not available: #{e.message}"
    false
  end

  def repository_link
    "https://your-domain.atlassian.net/rest/api/3/project#{@repo.name}"
  end

  private

  def git_repo(json, config)
    uri = json['repository']['ssh_url'] || json['repository']['url']
    name = json['repository']['full_name']
    default_branch = json['repository']['master_branch']
    head_commit_hash = json['head_commit']['id']
    GitRepo.new(
      uri: uri,
      name: name,
      id_rsa: config['id_rsa'],
      master: default_branch,
      head_commit_hash: head_commit_hash
    )
  end
end
