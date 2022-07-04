# Copyright (c) 2016-2022 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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

  def repository(name = nil)
    @client.Project.find(name)
  rescue JIRA::NotFound => e
    raise "Repository #{name} is not available: #{e.message}"
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
    repository(name) # checks that repository exists
    GitRepo.new(
      uri: uri,
      name: name,
      id_rsa: config['id_rsa'],
      master: default_branch,
      head_commit_hash: head_commit_hash
    )
  end
end
