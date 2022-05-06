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
# AbstractVCS - provides a uniform interface to work with different VCSes
#
class AbstractVCS
  attr_reader :is_valid, :repo, :name

  def initialize(client, json, config = {})
    @name = 'NAME OF VCS'
    @json = json
    @client = client
    @config = config
    @is_valid = nil
    @repo = nil
  end

  def issue(_issue_id)
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
    raise NotImplementedError, 'Should accept issue_id and return issue data'
  end

  def close_issue(_issue_id)
    # Input:
    # issue_id -> Number | String
    #
    # Output:
    # nil
    raise NotImplementedError, 'Should accept issue_id and return void'
  end

  def create_issue(_data)
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
    #   number: String,
    #   html_url: String,
    # }
    raise NotImplementedError, 'Should accept data and return created issue'
  end

  def update_issue(_issue_id, _data)
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
    raise NotImplementedError, 'You must implement this method'
  end

  def labels
    # Output:
    # {
    #   id: Number,
    #   name: String,
    #   color: String,
    # }[]
    raise NotImplementedError, 'You must implement this method'
  end

  def add_label(_label, _color)
    # Input:
    # label -> String
    # color -> String
    #
    # Output:
    # nil
    raise NotImplementedError, 'You must implement this method'
  end

  def add_labels_to_an_issue(_issue_id, _labels)
    # Input:
    # issue_id -> Number | String
    # labels -> String[]
    #
    # Output:
    # nil
    raise NotImplementedError, 'You must implement this method'
  end

  def add_comment(_issue_id, _comment)
    # Input:
    # issue_id -> Number | String
    # comment -> String
    #
    # Output:
    # nil
    raise NotImplementedError, 'You must implement this method'
  end

  def create_commit_comment(_sha, _comment)
    # Input:
    # sha -> String
    # comment -> String
    #
    # Output:
    # {
    #   html_url: String,
    # }
    raise NotImplementedError, 'You must implement this method'
  end

  def list_commits
    # Output:
    # {
    #   sha: String,
    #   html_url: String,
    # }[]
    raise NotImplementedError, 'You must implement this method'
  end

  def user(_username)
    # Input:
    # username -> String
    #
    # Output:
    # {
    #   name: String,
    #   email: String,
    # }
    raise NotImplementedError, 'You must implement this method'
  end

  def star
    # Output:
    # nil
    raise NotImplementedError, 'You must implement this method'
  end

  def repository(_name = nil)
    # Input:
    # name -> String = nil
    #
    # Output:
    # {
    #   private: Boolean,
    # }
    raise NotImplementedError, 'You must implement this method'
  end

  def repository_link
    # Output:
    # link -> String
    raise NotImplementedError, 'You must implement this method'
  end

  def collaborators_link
    # Output:
    # link -> String
    raise NotImplementedError, 'You must implement this method'
  end

  def file_link(_file)
    # Input:
    # file -> String
    #
    # Output:
    # link -> String
    raise NotImplementedError, 'You must implement this method'
  end

  def puzzle_link_for_commit(_sha, _file, _start, _stop)
    # Input:
    # sha -> String
    # file -> String
    # start -> Number
    # stop -> Number
    #
    # Output:
    # link -> String
    raise NotImplementedError, 'You must implement this method'
  end

  def issue_link(_issue_id)
    # Input:
    # issue_id -> String
    #
    # Output:
    # link -> String
    raise NotImplementedError, 'You must implement this method'
  end

  private

  def git_repo
    # Output:
    # repo -> GitRepo
    raise NotImplementedError, 'You must implement this method'
  end
end
