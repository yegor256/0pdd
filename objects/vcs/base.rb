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

#
# VCS - provides a uniform interface to work with different VCSes
#
module VCS
  attr_reader :is_valid, :repo, :name

  def initialize(client, json, config = {})
    @name = 'NAME OF VCS'
    @json = json
    @client = client
    @config = config
    @is_valid = nil
    @repo = nil
  end

  def issue(issue_id)
    # Input:
    # issue_id -> Number | String
    #
    # Output:
    # {
    #   state: 'closed' | 'open'
    #   author: {
    #     id: String,
    #     username: String,
    #   },
    #   milestone: {
    #     number: Number,
    #     title: String,
    #   },
    # }
    fail NotImplementedError, "Should accept issue_id and return issue data" 
  end

  def close_issue(issue_id)
    # Input:
    # issue_id -> Number | String
    #
    # Output:
    # nil
    fail NotImplementedError, "Should accept issue_id and return void" 
  end

  def create_issue(data)
    # Input:
    # {
    #   title: String,
    #   description: String,
    #   assignee_id?: Integer,
    #   milestone_id?: Integer,
    #   labels?: String[]
    # }
    #
    # Output:
    # {
    #   id: Number,
    #   title: String,
    #   url: String,
    #   html_url: String,
    #   state: String,
    #   labels: String[],
    # }
    fail NotImplementedError, "Should accept data and return created issue"
  end

  def update_issue(issue_id, data)
    # Input:
    # issue_id -> Number | String
    # data -> {
    #   title?: String,
    #   description?: String,
    #   assignee_id?: Integer,
    #   milestone_id?: Integer,
    #   state?: 'open' | 'closed',
    #   labels?: String[]
    # }
    #
    # Output:
    # nil
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def labels
    # Output:
    # {
    #   id: Number,
    #   name: String,
    #   color: String,
    # }[]
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def add_label(label, color)
    # Input:
    # label -> String
    # color -> String
    #
    # Output:
    # nil
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def add_labels_to_an_issue(issue_id, labels)
    # Input:
    # issue_id -> Number | String
    # labels -> String[]
    #
    # Output:
    # nil
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def add_comment(issue_id, comment)
    # Input:
    # issue_id -> Number | String
    # comment -> String
    #
    # Output:
    # nil
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def create_commit_comment(sha, comment)
    # Input:
    # sha -> String
    # comment -> String
    #
    # Output:
    # {
    #   html_url: String,
    # }
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def list_commits
    # Output:
    # {
    #   sha: String,
    #   html_url: String,
    # }[]
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def user(username)
    # Input:
    # username -> String
    #
    # Output:
    # { 
    #   name: String,
    #   email: String,
    # }
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def star
    # Output:
    # nil
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def repository()
    # returns { default_branch, private }
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def repository_link
    # Output:
    # link -> String
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def collaborators_link
    # Output:
    # link -> String
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def file_link(file)
    # Input:
    # file -> String
    #
    # Output:
    # link -> String
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def puzzle_link_for_commit(sha, file, start, stop)
    # Input:
    # sha -> String
    # file -> String
    # start -> Number
    # stop -> Number
    #
    # Output:
    # link -> String
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  def issue_link(issue_id)
    # Input:
    # issue_id -> String
    #
    # Output:
    # link -> String
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end

  private

  # TODO::
  def git_repo
    fail NotImplementedError, "A canine class must be able to #bark!" 
  end
end
