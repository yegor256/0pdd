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
require_relative '../git_repo'

#
# Github VCS
#
class GithubRepo
  attr_reader :is_valid, :repo, :name

  def initialize(client, json, config = {})
    @name = 'GITHUB'
    @client = client
    @config = config
    @json = json
    @is_valid = json['repository'] && json['repository']['full_name'] &&
    json['ref'] == "refs/heads/#{json['repository']['master_branch']}" &&
    json['head_commit'] && json['head_commit']['id']

    @repo = git_repo if @is_valid
  end

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
  # therefore leaving the job in a non deterministic state. Catch and track the error here to
  # prevent this from happening. Also applies to `add_comment(...)`
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

  def repository(name = nil)
    @client.repository(name || @repo.name)
  rescue Octokit::NotFound => e
    raise "Repository #{name} is not available: #{e.message}"
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

  def git_repo
    uri = @json['repository']['ssh_url'] || @json['repository']['url']
    name = @json['repository']['full_name']
    default_branch = @json['repository']['master_branch']
    head_commit_hash = @json['head_commit']['id']
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
