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

module VCS
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
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def repo_name
    fail NotImplementedError, "Should return full repository name" 
  end

  def issue(issue_id)
    # issue_id -> Number | String
    fail NotImplementedError, "Should accept issue_id and return { state, user: { login }}" 
  end

  def close_issue(issue_id)
    # issue_id -> Number | String
    fail NotImplementedError, "Should accept issue_id and return void" 
  end

  def create_issue(title, body)
    # title -> String
    # body ->
    #   :description (String) — The description of an issue.
    #   :assignee_id (Integer) — The ID of a user to assign issue.
    #   :milestone_id (Integer) — The ID of a milestone to assign issue.
    #   :labels (String) — Comma-separated label names for an issue.
    fail NotImplementedError, "Should accept title, body and return void" 
  end

  def update_issue(issue_id, data)
    # issue_id -> Number | String
    # data ->
    #   :title (String) — The title of an issue.
    #   :description (String) — The description of an issue.
    #   :assignee_id (Integer) — The ID of a user to assign issue.
    #   :milestone_id (Integer) — The ID of a milestone to assign issue.
    #   :labels (String) — Comma-separated label names for an issue.
    #   :state_event (String) — The state event of an issue ('close' or 'reopen').
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def labels()
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def add_label(label, color, options = {})
    # label -> String
    # color -> String
    # options ->
    # :
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def add_labels_to_an_issue(issue_id, tags)
    # issue_id -> String
    # tags -> String[]
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def add_comment(issue_id, comment)
    # issue_id -> String
    # comment -> String
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def create_commit_comment(hash, comment)
    # hash -> String
    # comment -> String
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def list_commits
    # returns { sha }[]
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def user(username)
    # username -> String
    # returns { email }
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def star()
    # returns String
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def repository()
    # returns { default_branch, private }
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def repository_link
    # returns String
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def collaborators_link
    # returns String
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def file_link(file)
    # file -> String
    # returns String
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def issue_link(issue_id)
    # issue_id -> String
    # returns String
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end
end
