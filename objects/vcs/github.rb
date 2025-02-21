# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'octokit'
require_relative '../git_repo'

#
# Github VCS
#
class GithubRepo
  attr_reader :repo, :name

  def initialize(client, json, config = {})
    @name = 'github'
    @client = client
    @config = config
    @json = json
    @repo = git_repo(json, config)
  end

  # Check whether this repository exists in GitHub and we have
  # access to it. Well, the actual access permissions are not checked
  # here, but we only try to read properties of the repo. If such a HTTP
  # request fails, the method returns FALSE.
  def exists?
    @client.repository(@repo.name)
    true
  rescue Octokit::NotFound => e
    puts "Repository #{@repo.name} is not available: #{e.message}"
    false
  end

  # Read information about one issue in GitHub and return it
  # as a map.
  def issue(issue_id)
    hash = @client.issue(@repo.name, issue_id)
    id = hash[:user][:id] if hash[:user]
    username = hash[:user][:login] if hash[:user]
    {
      state: hash[:state],
      author: {
        id: id,
        username: username
      },
      milestone: hash[:milestone]
    }
  end

  # @todo #312:30min Currently, if 0pdd fails to close an issue it causes all other downstream execution to be skipped
  #  therefore leaving the job in a non deterministic state. Catch and track the error here to
  #  prevent this from happening. Also applies to `add_comment(...)`
  def close_issue(issue_id)
    @client.close_issue(@repo.name, issue_id)
  end

  def create_issue(data)
    options = data.reject { |k| %i[title description].include? k }
    @client.create_issue(
      @repo.name,
      data[:title],
      data[:description],
      options
    )
  end

  def update_issue(issue_id, data)
    @client.update_issue(@repo.name, issue_id, data)
  end

  def labels
    @client.labels(@repo.name)
  end

  def add_label(label, color)
    @client.add_label(@repo.name, label, color)
  end

  def add_labels_to_an_issue(issue_id, labels)
    @client.add_labels_to_an_issue(@repo.name, issue_id, labels)
  end

  def add_comment(issue_id, comment)
    @client.add_comment(@repo.name, issue_id, comment)
  end

  def create_commit_comment(sha, comment)
    @client.create_commit_comment(@repo.name, sha, comment)
  end

  def list_commits
    @client.commits(@repo.name)
  end

  def user(username)
    @client.user(username)
  end

  def star
    @client.star(@repo.name)
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

  def puzzle_link_for_commit(sha, file, start, stop)
    "https://github.com/#{@repo.name}/blob/#{sha}/#{file}#L#{start}-L#{stop}"
  end

  def issue_link(issue_id)
    "https://github.com/#{@repo.name}/issues/#{issue_id}"
  end

  private

  def git_repo(json, config)
    uri = json['repository']['ssh_url'] || json['repository']['url']
    target = json['ref']
    name = json['repository']['full_name']
    default_branch = json['repository']['master_branch']
    head_commit_hash = json['head_commit'] ? json['head_commit']['id'] : ''
    GitRepo.new(
      uri: uri,
      name: name,
      id_rsa: config['id_rsa'],
      target: target,
      master: default_branch,
      head_commit_hash: head_commit_hash
    )
  end
end
