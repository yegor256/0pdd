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

require 'octokit'
require_relative '../git_repo.rb'
require_relative 'base'
require_relative '../clients/gitlab'

#
# Gitlab client
# API: https://github.com/NARKOZ/gitlab
#
class GithubHelper
  include VCS # important to include this module
  attr_reader :is_valid, :repo, :name

  def initialize(client, json, config = {})
    @name = 'GITHUB'
    @client = client
    @config = config
    @json = json
    @id = @json['repository']['full_name']
    @is_valid = json['repository'] && json['repository']['full_name'] &&
    json['ref'] == "refs/heads/#{json['repository']['master_branch']}" &&
    json['head_commit'] && json['head_commit']['id']

    @repo = git_repo() if @is_valid
  end

  private def git_repo()
    uri = @json['repository']['ssh_url'] || @json['repository']['url']
    name = @id
    head_commit_hash = @json['head_commit']['id']
    begin
      repo = @client.repository
    rescue Octokit::InvalidRepository => e
      raise "Repository #{name} is not available: #{e.message}"
    rescue Octokit::NotFound
      error 400
    end
    GitRepo.new(
      uri: uri,
      name: name,
      id_rsa: @config['id_rsa'],
      master: repo['default_branch'],
      head_commit_hash: head_commit_hash
    )
  end

  def repo_name
    @json['repository']['full_name']
  end

  def issue(issue_id) # returns {state, user:{login}}
    @client.issue(@id, issue_id)
  end

  def close_issue(issue_id) # returns void
    @client.close_issue(@id, issue_id)
  rescue Octokit::NotFound => e
    puts "The issue most probably is not found, can't close: #{e.message}"
  end

  def create_issue(title, body)
    # :description (String) — The description of an issue.
    # :assignee_id (Integer) — The ID of a user to assign issue.
    # :milestone_id (Integer) — The ID of a milestone to assign issue.
    # :labels (String) — Comma-separated label names for an issue.
    @client.create_issue(@id, title, body)
  end

  def update_issue(issue_id, data)
    @client.update_issue(@id, issue_id, data)
  end

  def labels() # returns void
    @client.labels(@id)
  end

  def add_label(label, color, options = {}) # returns void
    @client.add_label(@id, label, color, options)
  end

  def add_labels_to_an_issue(issue_id, tags) # returns void
    @client.add_labels_to_an_issue(@id, issue_id, tags)
  end

  def add_comment(issue_id, comment)  # returns void
    @client.add_comment(@id, issue_id, comment)
  rescue Octokit::NotFound => e
    puts "The issue most probably is not found, can't comment: #{e.message}"
  end

  def create_commit_comment(hash, comment) # returns void
    @client.create_commit_comment(@id, hash, comment)
  end

  def list_commits()
    @client.commits(@id)
  end

  def user(username)
    @client.user(username)
  end

  def star()
    @client.star(@id)
  end

  def repository()
    @client.repository(@id)
  end

  def repository_link
    "https://github.com/#{@repo.name}"
  end

  def collaborators_link
    "https://github.com/#{@repo.name}/settings/collaboration"
  end

  def file_link(file)
    "https://github.com/#{@repo.name}/blob/#{@repo.master}/#{file})"
  end

  def issue_link(issue_id)
    "https://github.com/#{@repo.name}/issues/#{issue_id}"
  end
end
