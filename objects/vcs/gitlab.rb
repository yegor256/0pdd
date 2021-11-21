# Copyright (c) 2016-2021 Yegor Bugayenko
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

require_relative '../git_repo.rb'
require_relative 'vcs'
require_relative '../clients/gitlab'

#
# Gitlab client
# API: https://github.com/NARKOZ/gitlab
#
class GitlabHelper
  include VCS
  attr_reader :repo, :name

  def initialize(client, json, config = {})
    @name = 'gitlab'
    @client = client
    @config = config
    @json = json
    @project = json['project']
    @repo = git_repo()
    @id = json['project']['id']
  end

  def repo_name()
    repo_name(@project['path_with_namespace'])
  end

  private def git_repo()
    uri = @project['url']
    name = @project['path_with_namespace']
    branch = @project['default_branch']
    head_commit_hash = @json['checkout_sha']
    begin
      @client.project(name)
    rescue Gitlab::Error::NotFound => e
      raise "Repository #{name} is not available: #{e.message}"
    rescue Gitlab::Error::Forbidden => e
        raise "Repository #{name} is not accessible: #{e.message}"
      error 400
    end
    GitRepo.new(
      uri: uri,
      name: name,
      id_rsa: @config['id_rsa'],
      master: branch,
      head_commit_hash: head_commit_hash
    )
  end

  def issue(repo, puzzle)
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def close_issue(repo, issue)
    @client.close_issue(@id, issue['id'])
  end

  def create_issue(repo, issue)
    # :description (String) — The description of an issue.
    # :assignee_id (Integer) — The ID of a user to assign issue.
    # :milestone_id (Integer) — The ID of a milestone to assign issue.
    # :labels (String) — Comma-separated label names for an issue.
    @client.create_issue(@id, issue['title'], issue)
  end

  def update_issue(repo, issue)
    # :title (String) — The title of an issue.
    # :description (String) — The description of an issue.
    # :assignee_id (Integer) — The ID of a user to assign issue.
    # :milestone_id (Integer) — The ID of a milestone to assign issue.
    # :labels (String) — Comma-separated label names for an issue.
    # :state_event (String) — The state event of an issue ('close' or 'reopen').
    @client.edit_issue(@id, issue['id'], issue)
  end

  def labels(repo)

  end

  def add_label(repo)

  end

  def add_labels_to_an_issue(repo, issue, tags)
    @client.add_labels_to_an_issue(@id, issue['id'], tags)
  end

  def add_comment(repo, issue, comment) 
    @client.create_issue_note(@id, issue['id'], comment)
  end

  def create_commit_comment(repo, sha, comment)
    @client.create_commit_comment(@id, sha, comment)
  end

  def list_commits(repo)
    @client.commits(@id)
  end

  def user(username)
    @client.user(username)
  end

  def star(name)
    @client.project(name)
  end

  def repository(name)
    @client.project(name)
  end

  def collaborators_link
    "https://gitlab.com/#{@repo.name}/project_members"
  end

  def file_link(file)
    "https://gitlab.com/#{@repo.name}/blob/#{@repo.master}/#{file})"
  end
end
