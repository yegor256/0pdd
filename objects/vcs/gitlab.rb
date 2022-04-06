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

require 'gitlab'
require_relative 'base'
require_relative '../git_repo'
require_relative '../clients/gitlab'

#
# Gitlab repo
# API: https://github.com/NARKOZ/gitlab
#
class GitlabRepo < AbstractVCS
  attr_reader :is_valid, :repo, :name

  def initialize(client, json, config = {})
    @name = 'GITLAB'
    @client = client
    @config = config
    @json = json
    @is_valid = json['project'] && json['project']['path_with_namespace'] &&
    json['ref'] == "refs/heads/#{json['project']['default_branch']}" &&
    json['checkout_sha']

    @repo = git_repo() if @is_valid
  end

  def issue(issue_id)
    hash = JSON.parse(
      @client.issue(@repo.name, issue_id).to_hash.to_json,
      symbolize_names: true
    )
    number, title = hash[:milestone].values_at(:id, :title) if hash[:milestone]
    { 
      state: hash[:state],
      author: hash[:author],
      milestone: {
        number: number,
        title: title,
      }
    }
  rescue Gitlab::Error::NotFound => e
    puts "The issue most probably is not found, can' comment: #{e.message}"
  end

  def close_issue(issue_id)
    @client.close_issue(@repo.name, issue_id)
  rescue Gitlab::Error::NotFound => e
    puts "The issue most probably is not found, can't close: #{e.message}"
  end

  def create_issue(data)
    options = data.reject {|k,v| k == :title}
    hash = JSON.parse(
      @client.create_issue(@repo.name, data[:title], options).to_hash.to_json,
      symbolize_names: true
    )
    { number: hash[:iid], html_url: hash[:web_url] }
  end

  def update_issue(issue_id, data)
    @client.edit_issue(@repo.name, issue_id, data)
  end

  def labels
    result = []
    @client.labels(@repo.name).each_page do |page|
      page.each do |label|
        result << JSON.parse(
          label.to_hash.to_json,
          symbolize_names: true
        )
      end
    end
    result
  end

  def add_label(label, color)
    @client.add_label(@repo.name, label, color)
  end

  def add_labels_to_an_issue(issue_id, labels)
    @client.edit_issue(@repo.name, issue_id, { labels: labels })
  end

  def add_comment(issue_id, comment) 
    @client.create_issue_note(@repo.name, issue_id, comment)
  rescue Gitlab::Error::NotFound => e
    puts "The issue most probably is not found, can't comment: #{e.message}"
  end

  def create_commit_comment(sha, comment)
    hash = JSON.parse(
      @client.create_commit_comment(@repo.name, sha, comment).to_hash.to_json,
      symbolize_names: true
    )
    hash[:html_url] = "https://gitlab.com/#{@repo.name}/commit/#{sha}"
    hash
  end

  def list_commits
    commits = []
    @client.commits(@repo.name).each_page do |page|
      page.each do |commit|
        commits << { sha: commit.id, html_url: commit.web_url }
      end
    end
    commits
  end

  def user(username)
    hash = JSON.parse(
      @client.user(username).to_hash.to_json,
      symbolize_names: true
    )
    hash[:email] = hash[:public_email]
    hash
  end

  def star
    @client.star_project(@repo.name)
  end

  def repository(name = nil)
    hash = JSON.parse(
      @client.project(name || @repo.name).to_hash.to_json,
      symbolize_names: true
    )
    hash[:private] = hash[:visibility] == 'private'
    hash
  rescue Gitlab::Error::NotFound => e
    raise "Repository #{name} is not available: #{e.message}"
  rescue Gitlab::Error::Forbidden => e
    raise "Repository #{name} is not accessible: #{e.message}"
  end

  def repository_link
    "https://gitlab.com/#{@repo.name}"
  end

  def collaborators_link
    "https://gitlab.com/#{@repo.name}/project_members"
  end

  def file_link(file)
    "https://gitlab.com/#{@repo.name}/blob/#{@repo.master}/#{file})"
  end

  def puzzle_link_for_commit(sha, file, start, stop)
    "https://gitlab.com/#{@repo.name}/blob/#{sha}/#{file}#L#{start}-L#{stop}"
  end

  def issue_link(issue_id)
    "https://gitlab.com/#{@repo.name}/issues/#{issue_id}"
  end

  private

  def git_repo
    uri = @json['project']['url']
    name = @json['project']['path_with_namespace']
    default_branch = @json['project']['default_branch']
    head_commit_hash = @json['checkout_sha']
    repository(name) # checks that repository exists
    GitRepo.new(
      uri: uri,
      name: name,
      id_rsa: @config['id_rsa'],
      master: default_branch,
      head_commit_hash: head_commit_hash
    )
  end
end
